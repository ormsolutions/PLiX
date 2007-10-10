/**************************************************************************\
* Neumont PLiX (Programming Language in XML) Code Generator                *
*                                                                          *
* Copyright © Neumont University and Matthew Curland. All rights reserved. *
*                                                                          *
* The use and distribution terms for this software are covered by the      *
* Common Public License 1.0 (http://opensource.org/licenses/cpl) which     *
* can be found in the file CPL.txt at the root of this distribution.       *
* By using this software in any fashion, you are agreeing to be bound by   *
* the terms of this license.                                               *
*                                                                          *
* You must not remove this notice, or any other, from this software.       *
\**************************************************************************/
using System;
using System.Diagnostics;
using System.Globalization;
using System.Runtime.InteropServices;
using System.ComponentModel.Design;
using Microsoft.Win32;
using Microsoft.VisualStudio.Shell.Interop;
using Microsoft.VisualStudio.OLE.Interop;
using Microsoft.VisualStudio.Shell;
using Microsoft.VisualStudio.TextManager.Interop;
using Microsoft.VisualStudio;
using IServiceProvider = System.IServiceProvider;
using IOleServiceProvider = Microsoft.VisualStudio.OLE.Interop.IServiceProvider;
using Microsoft.VisualStudio.Package;
using System.Collections.Generic;
using System.Xml;
using System.Xml.Xsl;
using System.IO;
using System.ComponentModel;

namespace Neumont.Tools.CodeGeneration.Plix.Shell
{
	[ProvideToolWindow(typeof(PlixPackage.SnippetPreviewWindow), Style = VsDockStyle.Tabbed, Orientation = ToolWindowOrientation.Right, Window = ToolWindowGuids.Outputwindow)]
	[ProvideProfile(typeof(PlixPackage.SnippetPreviewWindowSettings), "ProgrammingLanguageInXml", "SnippetPreviewWindow", 114, 116, false, DescriptionResourceID=118)]
	partial class PlixPackage
	{
		#region SnippetPreviewWindowSettings class
		// As crazy as it sounds, it is much easier to provide a dialog page
		// than implementing simple settings. There is a lot more plumbing
		// provided in the managed framework for dialog pages.
		[Guid("3C59D6F9-6C1A-42E4-BAE4-26CC5A944EDF")]
		private sealed class SnippetPreviewWindowSettings : DialogPage
		{
			#region Member variables
			// If more settings are added, add a corresponding check in the OnApply override below
			private const string FormatterExtension_Default = "cs";
			private static string myCurrentFormatterExtension = FormatterExtension_Default;
			private string myFormatterExtension = FormatterExtension_Default;
			#endregion // Member variables
			#region Accessor properties
			/// <summary>
			/// FormatterExtension option
			/// </summary>
			[DefaultValue(FormatterExtension_Default)]
			public string FormatterExtension
			{
				get { return myFormatterExtension; }
				set { myFormatterExtension = value; }
			}

			/// <summary>
			/// Current VS session-wide setting for FormatterExtension
			/// </summary>
			public static string CurrentFormatterExtension
			{
				get { return myCurrentFormatterExtension; }
			}
			#endregion // Accessor Properties
			#region Base overrides
			/// <summary>
			/// Set the current values of the static properties
			/// to match the cached settings
			/// </summary>
			public override void LoadSettingsFromStorage()
			{
				base.LoadSettingsFromStorage();
				myCurrentFormatterExtension = myFormatterExtension;
			}
			/// <summary>
			/// Set local values for the current settings to determine later if the
			/// settings have changed in the OnApply method.
			/// </summary>
			/// <param name="e"></param>
			protected override void OnActivate(CancelEventArgs e)
			{
				myFormatterExtension = myCurrentFormatterExtension;
			}

			/// <summary>
			/// Invalidate each loaded ORM diagram to force a redraw of the shapes
			/// </summary>
			/// <param name="e"></param>
			protected override void OnApply(DialogPage.PageApplyEventArgs e)
			{
				myCurrentFormatterExtension = FormatterExtension;
				base.OnApply(e);
			}
			public void Apply()
			{
				PageApplyEventArgs args = new PageApplyEventArgs();
				args.ApplyBehavior = ApplyKind.Apply;
				OnApply(args);
			}
			#endregion // Base overrides
		}
		#endregion // SnippetPreviewWindowSettings class
		[Guid(GuidList.SnippetPreviewWindowGuidString)]
		private sealed class SnippetPreviewWindow : IVsSelectionEvents
		{
			#region Constants
			private static readonly Guid CSharpLanguageServiceGuid = new Guid("694DD9B6-B865-4C5B-AD85-86356E9C88DC");
			private static readonly Guid VBLanguageServiceGuid = new Guid("E34ACDC0-BAAE-11D0-88BF-00A0C9110049");
			// UNDONE: This is the Memory language service, which just shows php as plain text. It works
			// much better then Guid.Empty in displaying something we have no colorizer for. Note that
			// no language service works fine, but once you've set one on the IVsTextLines turing it off
			// does not work well.
			private static readonly Guid PHPLanguageServiceGuid = new Guid("DF38847E-CC19-11D2-8ADA-00C04F79E479");
			private static readonly Guid XmlLanguageServiceGuid = new Guid("f6819a78-a205-47b5-be1c-675b3c7f0b8e");
			#endregion // Constants
			#region Member variables
			// Tool window management fields
			private IVsWindowFrame myToolWindowFrame;
			private IVsTextLines myToolWindowTextLines;

			// Command and package management fields
			private PlixPackage myPackage;
			private Guid myCurrentLanguageServiceGuid;

			// Xml document tracking fields
			private IVsWindowFrame myXmlDocumentFrame;
			private IVsTextLines myXmlTextLines;
			private LanguageService myXmlLanguageService;
			private IVsTextView myXmlTextView;
			private Source myXmlSource;
			private int myXmlSourceChangeCount;
			private int myXmlCaretLine;
			private int myXmlCaretColumn;

			// Document cache information
			private string myXmlText;
			private IList<RecognizedElementInfo> myRecognizedElements;
			private XmlNamespaceTracker myNamespaceTracker;
			private int myLastElementIndex = -1;
			private int myParentChoiceCount;
			private int myParentChoiceOffset;
			#endregion // Member variables
			#region FormatterInfo structure
			/// <summary>
			/// Simple helper structure to help with multiple languages
			/// </summary>
			private struct FormatterInfo
			{
				private static FormatterInfo[] Formatters;
				private string myExtension;
				private Guid myLanguageService;
				private MenuCommand myMenuCommand;
				private FormatterInfo(MenuCommand menuCommand, string extension, Guid languageService)
				{
					myExtension = extension;
					myLanguageService = languageService;
					myMenuCommand = menuCommand;
				}
				public static void InitializeCommands(SnippetPreviewWindow window, OleMenuCommandService commandService)
				{
					string currentExtension = SnippetPreviewWindowSettings.CurrentFormatterExtension;
					FormatterInfo[] newFormatters = new FormatterInfo[]{
						// Assume sequential matching the Formatters order, softly enforced by
						// notes in CommandIds.h and PkgCmdID.cs
				        new FormatterInfo(CreateMenuCommand(window, (int)PkgCmdIDList.cmdidPlixCSharpFormatter), "cs", CSharpLanguageServiceGuid),
				        new FormatterInfo(CreateMenuCommand(window, (int)PkgCmdIDList.cmdidPlixVBFormatter), "vb", VBLanguageServiceGuid),
				        new FormatterInfo(CreateMenuCommand(window, (int)PkgCmdIDList.cmdidPlixPHPFormatter), "php", PHPLanguageServiceGuid),
				        };
					Formatters = newFormatters;
					for (int i = 0; i < newFormatters.Length; ++i)
					{
						FormatterInfo info = newFormatters[i];
						MenuCommand menuCommand = info.myMenuCommand;
						if (info.myExtension == currentExtension)
						{
							window.myCurrentLanguageServiceGuid = info.myLanguageService;
							menuCommand.Checked = true;
						}
						commandService.AddCommand(menuCommand);
					}
				}
				private static MenuCommand CreateMenuCommand(SnippetPreviewWindow window, int commandId)
				{
					return new MenuCommand(new EventHandler(window.SwitchToFormatter), new CommandID(GuidList.guidPlixPackageCmdSet, commandId));
				}
				public static void SwitchToFormatter(SnippetPreviewWindow window, MenuCommand command)
				{
					if (!command.Checked)
					{
						int index = command.CommandID.ID - Formatters[0].myMenuCommand.CommandID.ID;
						FormatterInfo info = Formatters[index];
						command.Checked = true;
						for (int i = 0; i < Formatters.Length; ++i)
						{
							if (i != index)
							{
								Formatters[i].myMenuCommand.Checked = false;
							}
						}
						SnippetPreviewWindowSettings settings = (SnippetPreviewWindowSettings)window.myPackage.GetDialogPage(typeof(SnippetPreviewWindowSettings));
						settings.FormatterExtension = info.myExtension;
						settings.Apply();
						Guid languageId = info.myLanguageService;
						window.myCurrentLanguageServiceGuid = languageId;
						window.myToolWindowTextLines.SetLanguageServiceID(ref languageId);
						window.Reformat();
					}
				}
			}
			private void SwitchToFormatter(object sender, EventArgs e)
			{
				FormatterInfo.SwitchToFormatter(this, (MenuCommand)sender);
			}
			#endregion // FormatterInfo structure
			#region Constructors
			public SnippetPreviewWindow(PlixPackage package)
			{
				myPackage = package;
				// Add our command handlers for menu (commands must exist in the .ctc file)
				OleMenuCommandService commandService = package.GetService(typeof(IMenuCommandService)) as OleMenuCommandService;
				if (commandService != null)
				{

					// Create the preview window menu item
					MenuCommand menuItem = new MenuCommand(new EventHandler(ShowSnippetPreviewWindow), new CommandID(GuidList.guidPlixPackageCmdSet, (int)PkgCmdIDList.cmdidPlixSnippetPreviewWindow));
					commandService.AddCommand(menuItem);

					// Handle the parent and self menus. Note that the self is handled separately so it can have a different glyph
					menuItem = new DynamicParentChoiceMenu(this, new CommandID(GuidList.guidPlixPackageCmdSet, (int)PkgCmdIDList.cmdidPlixSnippetPreviewParentChoice));
					commandService.AddCommand(menuItem);

					menuItem = new OleMenuCommand(new EventHandler(OnMenuSelfChoice), null, new EventHandler(OnStatusSelfChoice), new CommandID(GuidList.guidPlixPackageCmdSet, (int)PkgCmdIDList.cmdidPlixSnippetPreviewSelfChoice));
					commandService.AddCommand(menuItem);

					FormatterInfo.InitializeCommands(this, commandService);
				}
			}
			#endregion // Constructors
			#region Command handlers
			#region Dynamic parent choice menu handling
			/// <summary>
			/// Standard pattern for handling dynamic start menus
			/// </summary>
			private class DynamicParentChoiceMenu : OleMenuCommand
			{
				public DynamicParentChoiceMenu(SnippetPreviewWindow previewWindow, CommandID id)
					:
					base(new EventHandler(previewWindow.OnMenuParentChoice), null, new EventHandler(previewWindow.OnStatusParentChoice), id)
				{
				}
				public sealed override bool DynamicItemMatch(int cmdId)
				{
					int baseCmdId = CommandID.ID;
					int testId = cmdId - baseCmdId;
					if (testId >= 0 && testId < (int)(PkgCmdIDList.cmdidPlixSnippetPreviewParentChoiceEnd - PkgCmdIDList.cmdidPlixSnippetPreviewParentChoice + 1))
					{
						MatchedCommandId = testId;
						return true;
					}
					return false;
				}
			}
			private static int GetParentChoiceCount(IList<RecognizedElementInfo> elements, int elementIndex)
			{
				if (elementIndex == RecognizedElementInfo.NullParentIndex)
				{
					return 0;
				}
				int retVal = 0;
				do
				{
					++retVal;
					elementIndex = elements[elementIndex].ParentIndex;
				} while (elementIndex != RecognizedElementInfo.NullParentIndex);
				return retVal;
			}
			private void OnStatusParentChoice(object sender, EventArgs e)
			{
				OleMenuCommand command = (OleMenuCommand)sender;
				int matchIndex = command.MatchedCommandId;
				command.MatchedCommandId = 0;

				int choiceCount = myParentChoiceCount;
				// The last item is handled by the single-valued 'self' choice
				if (matchIndex < (choiceCount - 1))
				{
					command.Supported = true;
					command.Enabled = true;
					command.Visible = true;
					command.Supported = true;

					// We show the list backwards, adjust the index accordingly
					matchIndex = choiceCount - matchIndex - 1;
					command.Checked = matchIndex == myParentChoiceOffset;
					IList<RecognizedElementInfo> elements = myRecognizedElements;
					int elementIndex = myLastElementIndex;
					while (matchIndex > 0)
					{
						elementIndex = elements[elementIndex].ParentIndex;
						--matchIndex;
					}
					command.Text = elements[elementIndex].ElementName;
				}
				else
				{
					command.Supported = false;
				}
			}
			private void OnMenuParentChoice(object sender, EventArgs e)
			{
				int matchIndex = ((OleMenuCommand)sender).MatchedCommandId;
				int choiceCount = myParentChoiceCount;
				// The last item is handled by the single-valued 'self' choice
				if (matchIndex < (choiceCount - 1))
				{
					// We show the list backwards, adjust the index accordingly
					matchIndex = choiceCount - matchIndex - 1;
					if (matchIndex != myParentChoiceOffset)
					{
						myParentChoiceOffset = matchIndex;
						Reformat();
					}
				}
			}
			private void OnStatusSelfChoice(object sender, EventArgs e)
			{
				OleMenuCommand command = (OleMenuCommand)sender;
				int elementIndex = myLastElementIndex;
				bool turnOn = elementIndex != -1;
				command.Enabled = turnOn;
				command.Visible = turnOn;
				command.Checked = turnOn && myParentChoiceOffset == 0;
				if (turnOn)
				{
					command.Text = myRecognizedElements[elementIndex].ElementName;
				}
			}
			private void OnMenuSelfChoice(object sender, EventArgs e)
			{
				if (myLastElementIndex != -1 && myParentChoiceOffset != 0)
				{
					myParentChoiceOffset = 0;
					Reformat();
				}
			}
			#endregion // Dynamic parent choice menu handling
			/// <summary>
			/// Show the snippet preview window
			/// </summary>
			private void ShowSnippetPreviewWindow(object sender, EventArgs e)
			{
				EnsureWindowFrame().Show();
			}
			#endregion // Command handlers
			#region Public methods and accessors
			/// <summary>
			/// Make sure the window frame exists
			/// </summary>
			/// <returns>The <see cref="IVsWindowFrame"/></returns>
			public IVsWindowFrame EnsureWindowFrame()
			{
				IVsWindowFrame frame = myToolWindowFrame;
				if (frame == null)
				{
					CreateSnippetPreviewWindow();
					frame = myToolWindowFrame;
				}
				return frame;
			}
			/// <summary>
			/// Handle idle processing
			/// </summary>
			/// <param name="periodic">Set if this is a periodic callback</param>
			public void OnIdle(bool periodic)
			{
				if (periodic)
				{
					if (myXmlSource != null && myXmlDocumentFrame != null)
					{
						SetDocumentFrame(myXmlDocumentFrame);
					}
				}
			}
			#endregion // Public methods and accessors
			#region SnippetPreviewWindow Creation
			private void CreateSnippetPreviewWindow()
			{
				IServiceProvider serviceProvider = myPackage;
				ILocalRegistry3 locReg = (ILocalRegistry3)serviceProvider.GetService(typeof(ILocalRegistry));
				IntPtr pBuf = IntPtr.Zero;
				Guid iid = typeof(IVsTextLines).GUID;
				ErrorHandler.ThrowOnFailure(locReg.CreateInstance(
					typeof(VsTextBufferClass).GUID,
					null,
					ref iid,
					(uint)CLSCTX.CLSCTX_INPROC_SERVER,
					out pBuf));

				IVsTextLines textLines = null;
				IObjectWithSite objectWithSite = null;
				try
				{
					// Get an object to tie to the IDE
					textLines = (IVsTextLines)Marshal.GetObjectForIUnknown(pBuf);
					objectWithSite = textLines as IObjectWithSite;
					objectWithSite.SetSite(serviceProvider.GetService(typeof(IOleServiceProvider)));
					IVsTextBuffer buffer = (IVsTextBuffer)textLines;
					uint bufferFlags;
					buffer.GetStateFlags(out bufferFlags);
					bufferFlags |= (uint)BUFFERSTATEFLAGS.BSF_USER_READONLY;
					buffer.SetStateFlags(bufferFlags);
				}
				finally
				{
					if (pBuf != IntPtr.Zero)
					{
						Marshal.Release(pBuf);
					}
				}

				// assign an initial language service to the
				if (myCurrentLanguageServiceGuid != Guid.Empty)
				{
					ErrorHandler.ThrowOnFailure(textLines.SetLanguageServiceID(ref myCurrentLanguageServiceGuid));
				}

				// Create a std code view (text)
				IntPtr srpCodeWin = IntPtr.Zero;
				iid = typeof(IVsCodeWindow).GUID;

				// create code view (does CoCreateInstance if not in shell's registry)
				ErrorHandler.ThrowOnFailure(locReg.CreateInstance(
					typeof(VsCodeWindowClass).GUID,
					null,
					ref iid,
					(uint)CLSCTX.CLSCTX_INPROC_SERVER,
					out srpCodeWin));

				IVsCodeWindow codeWindow = null;
				try
				{
					// Get an object to tie to the IDE
					codeWindow = (IVsCodeWindow)Marshal.GetObjectForIUnknown(srpCodeWin);
				}
				finally
				{
					if (srpCodeWin != IntPtr.Zero)
					{
						Marshal.Release(srpCodeWin);
					}
				}

				ErrorHandler.ThrowOnFailure(codeWindow.SetBuffer(textLines));

				IVsWindowFrame windowFrame;
				IVsUIShell shell = (IVsUIShell)serviceProvider.GetService(typeof(IVsUIShell));
				Guid emptyGuid = Guid.Empty;
				Guid snippetPreviewWindowGuid = GuidList.SnippetPreviewWindowGuid;
				// CreateToolWindow ARGS
				// 0 - toolwindow.flags (initnew | toolbarhost)
				// 1 - 0 (the tool window ID)
				// 2- IVsWindowPane
				// 3- guid null
				// 4- persistent slot (same nr as the guid attr on tool window class)
				// 5- guid null
				// 6- ole service provider (null)
				// 7- tool window.windowTitle
				// 8- int[] for position (empty array)
				// 9- out IVsWindowFrame
				ErrorHandler.ThrowOnFailure(shell.CreateToolWindow(
					(uint)(__VSCREATETOOLWIN.CTW_fInitNew | __VSCREATETOOLWIN.CTW_fForceCreate | __VSCREATETOOLWIN.CTW_fToolbarHost), // init new and force create are the normal defaults
					0,
					(IVsWindowPane)codeWindow,
					ref emptyGuid,
					ref snippetPreviewWindowGuid,
					ref emptyGuid,
					null,
					Resources.SnippetPreviewWindowWindowTitle,
					null,
					out windowFrame));

				// Initialize the toolbar, display properties, and key bindings for our newly created toolwindow
				object toolbarHostObject;
				windowFrame.GetProperty((int)__VSFPROPID.VSFPROPID_ToolbarHost, out toolbarHostObject);
				Guid cmdSet = GuidList.guidPlixPackageCmdSet;
				((IVsToolWindowToolbarHost)toolbarHostObject).AddToolbar(VSTWT_LOCATION.VSTWT_LEFT, ref cmdSet, PkgCmdIDList.menuidSnippetPreviewToolbar);
				windowFrame.SetProperty((int)__VSFPROPID.VSFPROPID_BitmapResource, 300);
				windowFrame.SetProperty((int)__VSFPROPID.VSFPROPID_BitmapIndex, 0);
				Guid CmdUIGuidTextEditor = new Guid(0x8b382828, 0x6202, 0x11d1, 0x88, 0x70, 0, 0, 0xf8, 0x75, 0x79, 210);
				windowFrame.SetGuidProperty((int)__VSFPROPID.VSFPROPID_InheritKeyBindings, ref CmdUIGuidTextEditor);

				// Cache our settings
				myToolWindowFrame = windowFrame;
				myToolWindowTextLines = textLines;

				// Synchronize with the current document and start listening for selection changes
				IVsMonitorSelection monitor = (IVsMonitorSelection)serviceProvider.GetService(typeof(IVsMonitorSelection));
				object frameObject;
				IVsWindowFrame documentFrame = null;
				if (ErrorHandler.Succeeded(monitor.GetCurrentElementValue((uint)VSConstants.VSSELELEMID.SEID_DocumentFrame, out frameObject)) &&
					null != (documentFrame = frameObject as IVsWindowFrame))
				{
					SetDocumentFrame(documentFrame);
				}
				if (documentFrame == null || (myXmlSource != null && myLastElementIndex == -1))
				{
					Reformat();
				}
				// UNDONE: Do something with IVsWindowFrameNotify3 so we can turn off advising when the window is not visible
				uint monitorCookie;
				monitor.AdviseSelectionEvents(this, out monitorCookie);
			}
			#endregion SnippetPreviewWindow Creation
			#region Window update
			private void SetDocumentFrame(IVsWindowFrame frame)
			{
				IVsWindowFrame oldFrame = myXmlDocumentFrame;
				if (frame != oldFrame)
				{
					myXmlDocumentFrame = frame;
				}
				if (frame != null)
				{
					object docDataObject;
					IVsTextLines textLines;
					IVsTextBufferProvider bufferProvider;
					Guid currentLanguageServiceGuid;
					if (ErrorHandler.Succeeded(frame.GetProperty((int)__VSFPROPID.VSFPROPID_DocData, out docDataObject)) &&
						(null != (textLines = docDataObject as IVsTextLines) ||
						(null != (bufferProvider = docDataObject as IVsTextBufferProvider) &&
						ErrorHandler.Succeeded(bufferProvider.GetTextBuffer(out textLines)))) &&
						ErrorHandler.Succeeded(textLines.GetLanguageServiceID(out currentLanguageServiceGuid)) &&
						currentLanguageServiceGuid == XmlLanguageServiceGuid)
					{
						bool caretChanged = false;
						bool sourceChanged = false;
						LanguageService languageService = myXmlLanguageService;
						#region Retrieve and cache xml language service
						if (languageService == null)
						{
							IntPtr languageInfoPtr;
							IVsLanguageInfo languageInfo;
							IOleServiceProvider docViewServiceProvider;
							object SPFrameObject;
							Guid languageInfoIID = typeof(IVsLanguageInfo).GUID;
							if (ErrorHandler.Succeeded(frame.GetProperty((int)__VSFPROPID.VSFPROPID_SPFrame, out SPFrameObject)) &&
								null != (docViewServiceProvider = SPFrameObject as IOleServiceProvider) &&
								ErrorHandler.Succeeded(docViewServiceProvider.QueryService(ref currentLanguageServiceGuid, ref languageInfoIID, out languageInfoPtr)) &&
								languageInfoPtr != IntPtr.Zero)
							{
								try
								{
									if (null != (languageInfo = (IVsLanguageInfo)Marshal.GetObjectForIUnknown(languageInfoPtr)))
									{
										myXmlLanguageService = languageService = languageInfo as LanguageService;
									}
								}
								finally
								{
									Marshal.Release(languageInfoPtr);
								}
							}
						}
						#endregion // Retrieve and cache xml language service
						if (languageService == null)
						{
							return;
						}
						IVsTextLines oldTextLines = myXmlTextLines;
						Source source = languageService.GetSource(textLines);
						if (textLines != oldTextLines)
						{
							source = languageService.GetSource(textLines);
							if (source != null)
							{
								myXmlSource = source;
								myXmlSourceChangeCount = source.ChangeCount;
								myXmlTextLines = textLines;
								sourceChanged = true;
							}
							else
							{
								myXmlSource = null;
								myXmlTextLines = textLines;
							}
						}
						else if (oldTextLines != null &&
							source != null &&
							myXmlSourceChangeCount != source.ChangeCount)
						{
							sourceChanged = true;
							myXmlSource = source;
							myXmlSourceChangeCount = source.ChangeCount;
						}
						if (sourceChanged)
						{
							caretChanged = true;
							IVsTextView currentView;
							if (ErrorHandler.Succeeded(languageService.GetCodeWindowManagerForSource(source).CodeWindow.GetLastActiveView(out currentView)) && currentView != null)
							{
								currentView.GetCaretPos(out myXmlCaretLine, out myXmlCaretColumn);
							}
							myXmlTextView = currentView;
						}
						else if (source != null)
						{
							IVsTextView currentView;
							if (ErrorHandler.Succeeded(languageService.GetCodeWindowManagerForSource(source).CodeWindow.GetLastActiveView(out currentView)) && currentView != null)
							{
								IVsTextView oldView = myXmlTextView;
								if (currentView != oldView)
								{
									caretChanged = true;
									if (oldView == null)
									{
										sourceChanged = true;
									}
									myXmlTextView = currentView;
									currentView.GetCaretPos(out myXmlCaretLine, out myXmlCaretColumn);
								}
								else if (currentView != null)
								{
									int caretLine;
									int caretColumn;
									myXmlTextView.GetCaretPos(out caretLine, out caretColumn);
									if (caretLine != myXmlCaretLine ||
										caretColumn != myXmlCaretColumn)
									{
										myXmlCaretLine = caretLine;
										myXmlCaretColumn = caretColumn;
										caretChanged = true;
									}
								}
							}
							else if (myXmlTextView != null)
							{
								myXmlTextView = null;
								caretChanged = true;
							}
						}
						UpdateWindow(sourceChanged, caretChanged);
					}
					else
					{
						CurrentDocumentNotXml();
					}
				}
				else if (oldFrame != null)
				{
					CurrentDocumentNotXml();
				}
			}
			private void UpdateWindow(bool sourceChanged, bool caretChanged)
			{
				if (sourceChanged || caretChanged)
				{
					if (myXmlSource != null && myXmlTextView != null)
					{
						bool forceUIUpdate = false;
						if (sourceChanged)
						{
							UpdateDocumentCache();
						}
						IList<RecognizedElementInfo> elements = myRecognizedElements;
						int elementCount;
						int bestMatchIndex = -1;
						if (null != (elements = myRecognizedElements) &&
							0 != (elementCount = elements.Count))
						{
							int position = myXmlSource.GetPositionOfLineIndex(myXmlCaretLine, myXmlCaretColumn);
							for (int i = 0; i < elementCount; ++i)
							{
								RecognizedElementInfo element = elements[i];
								// Note the test for element.EndPosition + 1. This lets the preview window format
								// an element immediately after the close tag is typed.
								if (element.IsPure && position > element.StartPosition && position <= (element.EndPosition + 1))
								{
									bestMatchIndex = i;
									// Contained elements will be pure, or this would not have been pure
									RefineBestElementMatch(elements, elementCount, position, ref bestMatchIndex);
									break;
								}
							}
						}
						if (bestMatchIndex != myLastElementIndex)
						{
							if (bestMatchIndex != -1)
							{
								RecognizedElementInfo bestElement = elements[bestMatchIndex];
								forceUIUpdate = caretChanged && (myParentChoiceOffset != 0 || myLastElementIndex == -1);
								myLastElementIndex = bestMatchIndex;
								myParentChoiceOffset = 0;
								myParentChoiceCount = GetParentChoiceCount(elements, bestMatchIndex);
								Reformat();
							}
							else
							{
								forceUIUpdate = myLastElementIndex != -1;
								myLastElementIndex = -1;
								myParentChoiceOffset = 0;
								myParentChoiceCount = 0;
								Reformat();
							}
						}
						if (forceUIUpdate)
						{
							((IVsUIShell)myPackage.GetService(typeof(IVsUIShell))).UpdateCommandUI(0);
						}
					}
				}
			}
			private void Reformat()
			{
				int elementIndex = myLastElementIndex;
				string targetPlix;
				XmlNamespaceManager namespaceContext = null;
				if (elementIndex != -1)
				{
					IList<RecognizedElementInfo> elements = myRecognizedElements;
					int parentChoiceOffset = myParentChoiceOffset;
					while (parentChoiceOffset > 0)
					{
						elementIndex = elements[elementIndex].ParentIndex;
						--parentChoiceOffset;
					}
					RecognizedElementInfo element = elements[elementIndex];
					namespaceContext = myNamespaceTracker.CreateNamespaceManager(element.ElementIndex);
					targetPlix = myXmlText.Substring(element.StartPosition, element.Length);
				}
				else
				{
					targetPlix = Resources.SnippetPreviewWindowDefaultWindowPLiX;
				}
				XslCompiledTransform formatter = FormatterManager.GetFormatterTransform(SnippetPreviewWindowSettings.CurrentFormatterExtension);
				// From the plix stream, generate the code
				using (StringWriter writer = new StringWriter(CultureInfo.InvariantCulture))
				{
					using (XmlReader plixReader = (namespaceContext == null) ?
						XmlReader.Create(new StringReader(targetPlix)) :
						// UNDONE: Need to track xml:space and xml:lang along with the namespace
						XmlReader.Create(new StringReader(targetPlix), null, new XmlParserContext(null, namespaceContext, "", XmlSpace.None)))
					{
						formatter.Transform(plixReader, new XsltArgumentList(), writer);
					}
					SetWindowText(writer.ToString());
				}
			}
			private void CurrentDocumentNotXml()
			{
				myXmlSource = null;
				myXmlTextLines = null;
				UpdateDocumentCache(); // Clears other document-related elements
				myXmlTextView = null;
				myXmlDocumentFrame = null;
				Reformat();
			}
			private static void RefineBestElementMatch(IList<RecognizedElementInfo> elements, int elementCount, int position, ref int bestMatchIndex)
			{
				// We will either match this element or a contiguous immediate child
				for (int i = bestMatchIndex + 1; i < elementCount; ++i)
				{
					RecognizedElementInfo element = elements[i];
					if (!element.IsPure)
					{
						break;
					}
					// Note the test for element.EndPosition + 1. This lets the preview window format
					// an element immediately after the close tag is typed.
					if (position > element.StartPosition && position <= (element.EndPosition + 1))
					{
						bestMatchIndex = i;
						RefineBestElementMatch(elements, elementCount, position, ref bestMatchIndex);
						break;
					}
				}
			}
			private void UpdateDocumentCache()
			{
				Source source = myXmlSource;
				IVsTextLines textLines = myXmlTextLines;
				if (source == null || textLines == null)
				{
					myXmlText = null;
					myRecognizedElements = null;
					myNamespaceTracker = default(XmlNamespaceTracker);
					myLastElementIndex = -1;
					myParentChoiceCount = 0;
					myParentChoiceOffset = 0;
					return;
				}
				string xmlText = source.GetText();
				NameTable nameTable = new NameTable();
				// UNDONE: We'll need additional namespaces when extensions come into play
				string plixNamespace = nameTable.Add("http://schemas.neumont.edu/CodeGeneration/PLiX");
				string docComment = nameTable.Add("docComment");
				XmlReaderSettings readerSettings = new XmlReaderSettings();
				readerSettings.NameTable = nameTable;
				readerSettings.ProhibitDtd = false;
				readerSettings.IgnoreWhitespace = false;
				readerSettings.CheckCharacters = false;
				readerSettings.ValidationType = ValidationType.None;
				readerSettings.CloseInput = true;

				IList<RecognizedElementInfo> elements = new List<RecognizedElementInfo>();
				int lastParentIndex = RecognizedElementInfo.NullParentIndex;
				int lastIndexPending = RecognizedElementInfo.NullParentIndex;
				int elementNumber = -1;
				XmlNamespaceTracker namespaceTracker = default(XmlNamespaceTracker);
				using (StringReader stringReader = new StringReader(xmlText))
				{
					using (XmlReader reader = XmlReader.Create(stringReader, readerSettings))
					{
						IXmlLineInfo lineInfo = (IXmlLineInfo)reader;
						XmlNamespaceTracker.Creator trackerCreator = default(XmlNamespaceTracker.Creator);
						string namespaceUri;
						try
						{
							while (reader.Read())
							{
								XmlNodeType nodeType = reader.NodeType;
								lastIndexPending = RecognizedElementInfo.ResolveEndPosition(elements, lastIndexPending, lineInfo, textLines, nodeType);
								switch (nodeType)
								{
									case XmlNodeType.Element:
										++elementNumber;
										trackerCreator.OpenElement(reader, elementNumber);
										namespaceUri = reader.NamespaceURI;
										if (XmlUtility.TestElementName(namespaceUri, plixNamespace) ||
											// Hack to consider local elements pure inside doccomments and inside other local elements
											(lastParentIndex != RecognizedElementInfo.NullParentIndex &&
											namespaceUri.Length == 0 &&
											(XmlUtility.TestElementName(elements[lastParentIndex].ElementName, docComment) ? XmlUtility.TestElementName(elements[lastParentIndex].ElementNamespace, plixNamespace) : elements[lastParentIndex].ElementNamespace.Length == 0)))
										{
											int startPosition;
											// LineInfo gives one-based numbers, and the line position is after the opening
											// element <
											textLines.GetPositionOfLineIndex(lineInfo.LineNumber - 1, lineInfo.LinePosition - 2, out startPosition);
											elements.Add(new RecognizedElementInfo(startPosition, 0, lastParentIndex, elementNumber, reader.LocalName, namespaceUri));
											if (!reader.IsEmptyElement)
											{
												lastParentIndex = elements.Count - 1;
											}
											else
											{
												lastIndexPending = elements.Count - 1;
											}
										}
										else if (lastParentIndex != RecognizedElementInfo.NullParentIndex)
										{
											RecognizedElementInfo.SetImpureElement(elements, lastParentIndex);
											lastParentIndex = RecognizedElementInfo.NullParentIndex;
										}
										break;
									case XmlNodeType.EndElement:
										trackerCreator.CloseElement();
										namespaceUri = reader.NamespaceURI;
										if (lastParentIndex != RecognizedElementInfo.NullParentIndex &&
											(XmlUtility.TestElementName(namespaceUri, plixNamespace) ||
											// Repeat hack to consider local elements pure inside doccomments and inside other local elements
											(namespaceUri.Length == 0 &&
											(XmlUtility.TestElementName(elements[lastParentIndex].ElementName, docComment) ? XmlUtility.TestElementName(elements[lastParentIndex].ElementNamespace, plixNamespace) : elements[lastParentIndex].ElementNamespace.Length == 0))))
										{
											lastIndexPending = lastParentIndex;
											lastParentIndex = elements[lastParentIndex].ParentIndex;
										}
										break;
									case XmlNodeType.EntityReference:
										if (reader.CanResolveEntity)
										{
											reader.ResolveEntity();
										}
										break;
								}
							}
						}
						catch (XmlException)
						{
							if (lastParentIndex != RecognizedElementInfo.NullParentIndex)
							{
								// Don't use, the xml failed, but we can use up to here
								RecognizedElementInfo.SetImpureElement(elements, lastParentIndex);
							}
							lastIndexPending = RecognizedElementInfo.NullParentIndex;
						}
						RecognizedElementInfo.SetEndPosition(elements, lastIndexPending, xmlText.Length - 1);
						namespaceTracker = trackerCreator.GetTracker();
					}
				}
				myXmlText = xmlText;
				myRecognizedElements = elements;
				myNamespaceTracker = namespaceTracker;
				myLastElementIndex = -1;
			}
			private void SetWindowText(string newText)
			{
				IVsTextLines textLines = myToolWindowTextLines;
				if (textLines != null)
				{
					IVsTextBuffer buffer = (IVsTextBuffer)textLines;
					uint bufferFlags;
					buffer.GetStateFlags(out bufferFlags);
					if (0 != (bufferFlags & (uint)BUFFERSTATEFLAGS.BSF_USER_READONLY))
					{
						buffer.SetStateFlags(bufferFlags & ~((uint)BUFFERSTATEFLAGS.BSF_USER_READONLY));
					}
					else
					{
						bufferFlags |= (uint)BUFFERSTATEFLAGS.BSF_USER_READONLY;
					}
					int lastLine;
					int lastLineIndex;
					ErrorHandler.ThrowOnFailure(textLines.GetLastLineIndex(out lastLine, out lastLineIndex));
					newText = newText ?? "";
					int newLen = newText.Length;
					IntPtr pszText = Marshal.StringToCoTaskMemAuto(newText);
					try
					{
						ErrorHandler.ThrowOnFailure(textLines.ReplaceLines(0, 0, lastLine, lastLineIndex, pszText, newLen, null));
					}
					finally
					{
						Marshal.FreeCoTaskMem(pszText);
					}
					buffer.SetStateFlags(bufferFlags);
				}
			}
			#endregion // Window update
			#region IVsSelectionEvents Implementation
			int IVsSelectionEvents.OnCmdUIContextChanged(uint dwCmdUICookie, int fActive)
			{
				return 0;
			}
			int IVsSelectionEvents.OnElementValueChanged(uint elementid, object varValueOld, object varValueNew)
			{
				if (elementid == (uint)VSConstants.VSSELELEMID.SEID_DocumentFrame)
				{
					SetDocumentFrame(varValueNew as IVsWindowFrame);
				}
				return 0;
			}
			int IVsSelectionEvents.OnSelectionChanged(IVsHierarchy pHierOld, uint itemidOld, IVsMultiItemSelect pMISOld, ISelectionContainer pSCOld, IVsHierarchy pHierNew, uint itemidNew, IVsMultiItemSelect pMISNew, ISelectionContainer pSCNew)
			{
				return 0;
			}
			#endregion // IVsSelectionEvents Implementation
			#region XmlNamespaceTracker struct
			private struct XmlNamespaceTracker
			{
				private struct NamePair
				{
					public string Prefix;
					public string NamespaceUri;
					public NamePair(string prefix, string namespaceUri)
					{
						Prefix = prefix;
						NamespaceUri = namespaceUri;
					}
				}
				private struct NamespaceEntry
				{
					private sealed class ElementIndexComparer : IComparer<NamespaceEntry>
					{
						#region IComparer<NamespaceEntry> Implementation
						int IComparer<NamespaceEntry>.Compare(NamespaceEntry x, NamespaceEntry y)
						{
							return x.ElementIndex.CompareTo(y.ElementIndex);
						}
						#endregion // IComparer<NamespaceEntry> Implementation
					}
					public static readonly IComparer<NamespaceEntry> IndexComparer = new ElementIndexComparer();
					public int ElementIndex;
					public int PopScopeCount;
					public NamePair[] PushNames;
				}
				/// <summary>
				/// The sequential entries used to modify the namespaces. Note that
				/// we can binary search this list by element index
				/// </summary>
				private List<NamespaceEntry> myEntries;
				/// <summary>
				/// Create a new namespace manager that represents the namespace state
				/// immediately before the <paramref name="elementIndex"/>
				/// </summary>
				/// <param name="elementIndex"></param>
				/// <returns>A new XmlNamespaceManager, or <see langword="null"/></returns>
				public XmlNamespaceManager CreateNamespaceManager(int elementIndex)
				{
					XmlNamespaceManager retVal = null;
					List<NamespaceEntry> entries = myEntries;
					if (entries != null)
					{
						int entryCount = entries.Count;
						for (int i = 0; i < entryCount; ++i)
						{
							NamespaceEntry entry = entries[i];
							if (entry.ElementIndex >= elementIndex)
							{
								break;
							}
							else if (retVal == null)
							{
								retVal = new XmlNamespaceManager(new NameTable());
							}
							int popCount = entry.PopScopeCount;
							while (popCount != 0)
							{
								retVal.PopScope();
								--popCount;
							}
							NamePair[] names = entry.PushNames;
							if (names != null)
							{
								retVal.PushScope();
								for (int j = 0; j < names.Length; ++j)
								{
									retVal.AddNamespace(names[j].Prefix, names[j].NamespaceUri);
								}
							}
						}
					}
					return retVal;
				}
				public struct Creator
				{
					private XmlNamespaceManager myNamespaceManager;
					private int myPopPending;
					private Stack<int> myOpenElements;
					private XmlNamespaceTracker myTracker;
					/// <summary>
					/// A new element with the provide index has been opened
					/// </summary>
					/// <param name="reader">The <see cref="XmlReader"/> set to the beginning of a new element</param>
					/// <param name="elementIndex">The index of this element in the document.</param>
					public void OpenElement(XmlReader reader, int elementIndex)
					{
						// Don't both with empty elements. The point of this class is to get an XmlNamespaceManager
						// ready for use by a given element. An namespaces added in an empty element itself
						// will be handled natively by the reader.
						Debug.Assert(reader.NodeType == XmlNodeType.Element);
						if (!reader.IsEmptyElement)
						{
							if (reader.MoveToFirstAttribute())
							{
								XmlNamespaceManager namespaceManager = myNamespaceManager;
								List<NamePair> names = null;
								do
								{
									string value = null;
									string prefix = null;
									if (string.IsNullOrEmpty(reader.Prefix) && reader.LocalName == "xmlns")
									{
										prefix = "";
										value = reader.Value ?? "";
									}
									else if (reader.Prefix == "xmlns")
									{
										prefix = reader.LocalName;
										value = reader.Value ?? "";
									}
									if (prefix != null)
									{
										string existingUri;
										if (namespaceManager == null ||
											null == (existingUri = namespaceManager.LookupNamespace(prefix)) ||
											existingUri != value)
										{
											if (names == null)
											{
												names = new List<NamePair>();
											}
											names.Add(new NamePair(prefix, value));
										}
									}
								} while (reader.MoveToNextAttribute());
								if (names != null)
								{
									if (namespaceManager == null)
									{
										myNamespaceManager = namespaceManager = new XmlNamespaceManager(new NameTable());
									}
									NamePair[] namesArray = names.ToArray();
									namespaceManager.PushScope();
									for (int i = 0; i < namesArray.Length; ++i)
									{
										namespaceManager.AddNamespace(namesArray[i].Prefix, namesArray[i].NamespaceUri);
									}
									List<NamespaceEntry> entries = myTracker.myEntries;
									if (entries == null)
									{
										myTracker.myEntries = entries = new List<NamespaceEntry>();
									}
									NamespaceEntry entry = new NamespaceEntry();
									entry.PopScopeCount = myPopPending;
									myPopPending = 0;
									entry.ElementIndex = elementIndex;
									entry.PushNames = namesArray;
									entries.Add(entry);
								}
								reader.MoveToElement();
							}
							Stack<int> openElements = myOpenElements;
							if (openElements == null)
							{
								myOpenElements = openElements = new Stack<int>();
							}
							openElements.Push(elementIndex);
						}
					}
					/// <summary>
					/// An element at the given index has been closed. Must correspond to
					/// a balanced call to OpenElement.
					/// </summary>
					public void CloseElement()
					{
						int elementIndex = myOpenElements.Pop();
						if (myNamespaceManager != null)
						{
							List<NamespaceEntry> entries = myTracker.myEntries;
							if (entries != null)
							{
								NamespaceEntry findEntry = new NamespaceEntry();
								findEntry.ElementIndex = elementIndex;
								int index = entries.BinarySearch(findEntry, NamespaceEntry.IndexComparer);
								if (index >= 0 && entries[index].PushNames != null)
								{
									++myPopPending;
									myNamespaceManager.PopScope();
								}
							}
						}
					}
					public XmlNamespaceTracker GetTracker()
					{
						XmlNamespaceTracker tracker = myTracker;
						myOpenElements = null;
						myPopPending = 0;
						myNamespaceManager = null;
						myTracker.myEntries = null;
						return tracker;
					}
				}
			}
			#endregion // XmlNamespaceTracker struct
			#region RecognizedElementInfo
			/// <summary>
			/// A structure representing the location of a known element type in a stream
			/// </summary>
			[DebuggerDisplay("{myElementName}: Pure={myIsPureElement}")]
			private struct RecognizedElementInfo
			{
				public const int NullParentIndex = -1;
				private int myElementIndex;
				private int myStartPosition;
				private int myEndPosition;
				private bool myIsPureElement;
				private int myParentIndex;
				private string myElementName;
				private string myElementNamespace;
				/// <summary>
				/// Create a new <see cref="RecognizedElementInfo"/>
				/// </summary>
				/// <param name="startPosition"></param>
				/// <param name="endPosition"></param>
				/// <param name="parentIndex">The index of the parent for this element</param>
				/// <param name="elementIndex">The number of element in the original xml file</param>
				/// <param name="elementName">The element name</param>
				/// <param name="elementNamespace">The Xml namespace of the element</param>
				public RecognizedElementInfo(int startPosition, int endPosition, int parentIndex, int elementIndex, string elementName, string elementNamespace)
				{
					myStartPosition = startPosition;
					myEndPosition = endPosition;
					myParentIndex = parentIndex;
					myElementIndex = elementIndex;
					myIsPureElement = true;
					myElementName = elementName;
					myElementNamespace = elementNamespace;
				}
				/// <summary>
				/// Notify that this element and any of the parent elements are impure
				/// </summary>
				/// <param name="elements">A list of elements, will always include the parent element</param>
				/// <param name="index">The index of the element being changed to impure</param>
				public static void SetImpureElement(IList<RecognizedElementInfo> elements, int index)
				{
					while (index != NullParentIndex)
					{
						RecognizedElementInfo elementInfo = elements[index];
						if (elementInfo.myIsPureElement)
						{
							elementInfo.myIsPureElement = false;
							int nextIndex = elementInfo.myParentIndex;
							// Continue to track parents for pure indices only
							elementInfo.myParentIndex = NullParentIndex;
							elements[index] = elementInfo;
							index = nextIndex;
							continue;
						}
						break;
					}
				}
				public static void SetEndPosition(IList<RecognizedElementInfo> elements, int index, int endPosition)
				{
					if (index != NullParentIndex)
					{
						RecognizedElementInfo elementInfo = elements[index];
						elementInfo.myEndPosition = endPosition;
						elements[index] = elementInfo;
					}
				}
				public static int ResolveEndPosition(IList<RecognizedElementInfo> elements, int index, IXmlLineInfo lineInfo, IVsTextLines textLines, XmlNodeType nodeType)
				{
					int retVal = index;
					if (index != NullParentIndex)
					{
						retVal = NullParentIndex;
						RecognizedElementInfo elementInfo = elements[index];
						// Don't bother if this is an impure element, we'll just toss it
						if (elementInfo.myIsPureElement)
						{
							int elementAdjust = 0;
							switch (nodeType)
							{
								case XmlNodeType.Element:
									elementAdjust = 1;
									break;
								case XmlNodeType.EndElement:
								case XmlNodeType.XmlDeclaration:
								case XmlNodeType.ProcessingInstruction:
									elementAdjust = 2;
									break;
								case XmlNodeType.CDATA:
									elementAdjust = 9;
									break;
								case XmlNodeType.Comment:
									elementAdjust = 4;
									break;
							}
							int position;
							textLines.GetPositionOfLineIndex(lineInfo.LineNumber - 1, lineInfo.LinePosition - 1 - elementAdjust, out position);
							elementInfo.myEndPosition = position - 1;
							elements[index] = elementInfo;
						}
					}
					return retVal;
				}
				#region Accessor Properties
				/// <summary>
				/// Return the parent index for a pure element. Otherwise, returns
				/// <see cref="NullParentIndex"/>
				/// </summary>
				public int ParentIndex
				{
					get
					{
						return myParentIndex;
					}
				}
				/// <summary>
				/// Returns true if this element contains elements of handled xml types only
				/// </summary>
				public bool IsPure
				{
					get
					{
						return myIsPureElement;
					}
				}
				/// <summary>
				/// The index of this element in the document
				/// </summary>
				public int ElementIndex
				{
					get
					{
						return myElementIndex;
					}
				}
				/// <summary>
				/// The start position of this element in the text document
				/// </summary>
				public int StartPosition
				{
					get
					{
						return myStartPosition;
					}
				}
				/// <summary>
				/// The end position of this element in the text document
				/// </summary>
				public int EndPosition
				{
					get
					{
						return myEndPosition;
					}
				}
				/// <summary>
				/// The length of this element in the original document
				/// </summary>
				public int Length
				{
					get
					{
						return myEndPosition - myStartPosition + 1;
					}
				}
				/// <summary>
				/// The xml local name for this element
				/// </summary>
				public string ElementName
				{
					get
					{
						return myElementName;
					}
				}
				/// <summary>
				/// The xml namespace for this element
				/// </summary>
				public string ElementNamespace
				{
					get
					{
						return myElementNamespace;
					}
				}
				#endregion // Accessor Properties
			}
			#endregion // RecognizedElementInfo
		}
	}
}