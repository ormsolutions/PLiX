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
using System.Reflection;

namespace Neumont.Tools.CodeGeneration.Plix.Shell
{
	/// <summary>
	/// This is the class that implements the package exposed by this assembly.
	///
	/// The minimum requirement for a class to be considered a valid package for Visual Studio
	/// is to implement the IVsPackage interface and register itself with the shell.
	/// This package uses the helper classes defined inside the Managed Package Framework (MPF)
	/// to do it: it derives from the Package class that provides the implementation of the 
	/// IVsPackage interface and uses the registration attributes defined in the framework to 
	/// register itself and its components with the shell.
	/// </summary>
	// This attribute tells the registration utility (regpkg.exe) that this class needs
	// to be registered as package.
	[PackageRegistration(UseManagedResourcesOnly = true)]
	// A Visual Studio component can be registered under different registry roots; for instance
	// when you debug your package you want to register it in the experimental hive. This
	// attribute specifies the registry root to use if no one is provided to regpkg.exe with
	// the /root switch.
	[DefaultRegistryRoot("Software\\Microsoft\\VisualStudio\\8.0Exp")]
#if !VISUALSTUDIO_10_0
	// This attribute is used to register the informations needed to show the this package
	// in the Help/About dialog of Visual Studio.
	[InstalledProductRegistration(true, null, null, null, LanguageIndependentName = "Neumont PLiX Code Generator")]
#endif
	// In order be loaded inside Visual Studio in a machine that has not the VS SDK installed, 
	// package needs to have a valid load key (it can be requested at 
	// http://msdn.microsoft.com/vstudio/extend/). This attributes tells the shell that this 
	// package has a load key embedded in its resources.
	[ProvideLoadKey("Standard", "1.0", "Neumont PLiX Tools for Visual Studio", "Neumont University", 150)]
	// This attribute is needed to let the shell know that this package exposes some menus.
	[ProvideMenuResource(1000, 1)]
	[Guid(GuidList.guidPlixPackagePkgString)]
	public sealed partial class PlixPackage : Package, IOleComponent, IVsInstalledProduct
	{
		/////////////////////////////////////////////////////////////////////////////
		// Overriden Package Implementation
		#region Member variables
		/// <summary>
		/// Component id used for OnIdle registration
		/// </summary>
		private uint myComponentId;
		private SnippetPreviewWindow myPreviewWindow;
		#endregion // Member variables
		#region Package Members
		/// <summary>
		/// Initialization of the package; this method is called right after the package is sited, so this is the place
		/// where you can put all the initialization code that rely on services provided by VisualStudio.
		/// </summary>
		protected override void Initialize()
		{
			base.Initialize();

			if (!SetupMode)
			{
				// Ensure our settings are loaded
				GetDialogPage(typeof(SnippetPreviewWindowSettings));

				// Create the preview window
				myPreviewWindow = new SnippetPreviewWindow(this);

				// Enable idle handling
				IOleComponentManager componentManager;
				if (myComponentId == 0 &&
					null != (componentManager = (IOleComponentManager)GetService(typeof(SOleComponentManager))))
				{
					OLECRINFO[] pcrinfo = new OLECRINFO[1];
					pcrinfo[0].cbSize = (uint)Marshal.SizeOf(typeof(OLECRINFO));
					pcrinfo[0].grfcrf = (uint)(_OLECRF.olecrfNeedIdleTime | _OLECRF.olecrfNeedPeriodicIdleTime);
					pcrinfo[0].grfcadvf = (uint)(_OLECADVF.olecadvfModal | _OLECADVF.olecadvfRedrawOff); // Not sure why here, just following the Xml Editor Package
					pcrinfo[0].uIdleTimeInterval = 1000;
					componentManager.FRegisterComponent(this, pcrinfo, out myComponentId);
				}
			}
		}
		protected override void Dispose(bool disposing)
		{
			IOleComponentManager componentManager;
			if (myComponentId != 0 &&
				null != (componentManager = (IOleComponentManager)GetService(typeof(SOleComponentManager))))
			{
				uint componentId = myComponentId;
				myComponentId = 0;
				componentManager.FRevokeComponent(componentId);
			}
			base.Dispose(disposing);
		}
		private bool SetupMode
		{
			get
			{
				int num;
				string str;
				IVsAppCommandLine service = (IVsAppCommandLine)GetService(typeof(IVsAppCommandLine));
				ErrorHandler.ThrowOnFailure(service.GetOption("setup", out num, out str));
				return (num == 1);
			}
		}
		protected override void OnLoadOptions(string key, System.IO.Stream stream)
		{
			base.OnLoadOptions(key, stream);
		}
		#endregion // Package Members
		#region Idle handling
		private void OnIdle(bool periodic)
		{
			if (null != myPreviewWindow)
			{
				myPreviewWindow.OnIdle(periodic);
			}
		}
		#endregion // Idle handling
		#region IOleComponent implementation
		int IOleComponent.FDoIdle(uint grfidlef)
		{
			OnIdle(0 != (grfidlef & (uint)_OLEIDLEF.oleidlefPeriodic));
			return 0;
		}
		// This is implemented to get an idle callback only. All return values are based on the
		// Microsoft.XmlEditor.Package return codes for the same interface
		int IOleComponent.FContinueMessageLoop(uint uReason, IntPtr pvLoopData, MSG[] pMsgPeeked)
		{
			return 1;
		}
		int IOleComponent.FPreTranslateMessage(MSG[] pMsg)
		{
			return 0;
		}
		int IOleComponent.FQueryTerminate(int fPromptUser)
		{
			return 1;
		}
		int IOleComponent.FReserved1(uint dwReserved, uint message, IntPtr wParam, IntPtr lParam)
		{
			return 1;
		}
		IntPtr IOleComponent.HwndGetWindow(uint dwWhich, uint dwReserved)
		{
			return IntPtr.Zero;
		}
		void IOleComponent.OnActivationChange(IOleComponent pic, int fSameComponent, OLECRINFO[] pcrinfo, int fHostIsActivating, OLECHOSTINFO[] pchostinfo, uint dwReserved)
		{
		}
		void IOleComponent.OnAppActivate(int fActive, uint dwOtherThreadID)
		{
		}
		void IOleComponent.OnEnterState(uint uStateID, int fEnter)
		{
		}
		void IOleComponent.OnLoseActivation()
		{
		}
		void IOleComponent.Terminate()
		{
		}
		#endregion // IOleComponent implementation
		#region IVsInstalledProduct implementation
		[Obsolete("Visual Studio 2005 no longer calls this method.", true)]
		int IVsInstalledProduct.IdBmpSplash(out uint pIdBmp)
		{
			pIdBmp = 0;
			return VSConstants.E_NOTIMPL;
		}
		int IVsInstalledProduct.IdIcoLogoForAboutbox(out uint pIdIco)
		{
			pIdIco = 400;
			return VSConstants.S_OK;
		}

		int IVsInstalledProduct.OfficialName(out string pbstrName)
		{
			pbstrName = Resources.PackageProductName;
			return VSConstants.S_OK;
		}

		int IVsInstalledProduct.ProductDetails(out string pbstrProductDetails)
		{
			pbstrProductDetails = Resources.PackageProductDescription;
			return VSConstants.S_OK;
		}

		int IVsInstalledProduct.ProductID(out string pbstrPID)
		{
			pbstrPID = null;
			object[] customAttributes = typeof(PlixPackage).Assembly.GetCustomAttributes(typeof(AssemblyInformationalVersionAttribute), false);
			for (int i = 0; i < customAttributes.Length; i++)
			{
				AssemblyInformationalVersionAttribute informationalVersion = customAttributes[i] as AssemblyInformationalVersionAttribute;
				if (informationalVersion != null)
				{
					pbstrPID = informationalVersion.InformationalVersion;
					break;
				}
			}
			return VSConstants.S_OK;
		}

		#endregion // IVsInstalledProduct implementation
	}
}