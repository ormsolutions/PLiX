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
using System.Collections.Generic;
using System.Text;
using Reflector;
using Reflector.CodeModel;

namespace Reflector
{
	/// <summary>
	/// Starting point for a Reflector class
	/// </summary>
	public sealed class PLiXLanguagePackage : IPackage
	{
		#region Member Variables
		private ILanguageManager myLanguageManager;
		private ILanguage myLanguage;
		#endregion // Member Variables
		#region IPackage Implementation
		void IPackage.Load(IServiceProvider serviceProvider)
		{
			ILanguageManager languageManager = (ILanguageManager)serviceProvider.GetService(typeof(ILanguageManager));
			ILanguage language = new PLiXLanguage((ITranslatorManager)serviceProvider.GetService(typeof(ITranslatorManager)));
			languageManager.RegisterLanguage(language);
			myLanguageManager = languageManager;
			myLanguage = language;
		}
		void IPackage.Unload()
		{
			myLanguageManager.UnregisterLanguage(myLanguage);
		}
		#endregion // IPackage Implementation
	}
}
