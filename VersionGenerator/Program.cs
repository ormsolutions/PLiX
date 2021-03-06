#region Common Public License Copyright Notice
/**************************************************************************\
* Neumont Object-Role Modeling Architect for Visual Studio                 *
*                                                                          *
* Copyright � Neumont University. All rights reserved.                     *
* Copyright � ORM Solutions, LLC. All rights reserved.                     *
*                                                                          *
* The use and distribution terms for this software are covered by the      *
* Common Public License 1.0 (http://opensource.org/licenses/cpl) which     *
* can be found in the file CPL.txt at the root of this distribution.       *
* By using this software in any fashion, you are agreeing to be bound by   *
* the terms of this license.                                               *
*                                                                          *
* You must not remove this notice, or any other, from this software.       *
\**************************************************************************/
#endregion

using System;
using System.Configuration;
using System.Diagnostics;
using System.IO;
using System.Text.RegularExpressions;
using System.Xml;

namespace Neumont.Tools.ORM.SDK
{
	internal static partial class VersionGenerator
	{
		private static int Main(string[] args)
		{
			const string generatedWarning = "This file was generated by VersionGenerator.exe. It should NOT be directly modified.";
			const string statusPrefix = "VersionGenerator.exe: ";
			const string xmlDateFormat = "yyyy-MM-ddTHH:mm:ss.fffffffzzz";

			FileInfo versionConfig;
			Configuration customConfig = null;
			if (args.Length == 0)
			{
				Directory.SetCurrentDirectory(Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location));
				versionConfig = new FileInfo("VersionGenerator.exe.config");
				if (!versionConfig.Exists)
				{
					// If we don't have the configuration file, bad things are going to happen...
					Console.Error.WriteLine(statusPrefix + "VersionGenerator.exe.config not found!");
					return 1;
				}
			}
			else
			{
				// Load alternate configuration file and set current directory relative to this configuration file
				versionConfig = new FileInfo(args[0]);
				if (!versionConfig.Exists)
				{
					Console.Error.Write(statusPrefix + "Custom configuration file '" + args[0] + "' not found.");
					return 1;
				}

				Directory.SetCurrentDirectory(versionConfig.DirectoryName);

				ExeConfigurationFileMap configMap = new ExeConfigurationFileMap();
				configMap.ExeConfigFilename = versionConfig.FullName;
				customConfig = ConfigurationManager.OpenMappedExeConfiguration(configMap, ConfigurationUserLevel.None);
				Config.CustomConfig = customConfig;
			}

			TemplateConfigurationSection templateSettings = (customConfig != null ? customConfig.GetSection("templateSettings") : ConfigurationManager.GetSection("templateSettings")) as TemplateConfigurationSection;
			if (string.IsNullOrEmpty(templateSettings.LastGenerated))
			{
				// Require historical version control
				Console.Error.Write(statusPrefix + "templateSettings@last must specify a file name for change tracking.");
				return 1;
			}

			string gitCommand = Config.GitCommand;
			int major;
			int minor;
			int build;
			int revision;
			string hash;
			if (!string.IsNullOrEmpty(gitCommand))
			{
				ProcessStartInfo startInfo = new ProcessStartInfo();
				startInfo.UseShellExecute = false;
				startInfo.FileName = gitCommand;
				startInfo.Arguments = Config.GitCommandArgs;
				startInfo.RedirectStandardOutput = true;
				startInfo.CreateNoWindow = true;

				string gitVer;
				using (Process process = new Process())
				{
					process.StartInfo = startInfo;
					process.Start();
					process.WaitForExit();
					gitVer = process.StandardOutput.ReadLine();
				}
				GroupCollection groups = Regex.Match(gitVer, @"(?:\D)*(?<major>\d+)\.(?<minor>\d+)\.(?<build>\d+)\.(?<revision>\d+)(?:-g(?<hash>.*?))?$").Groups;
				Group group;
				string gitVal;
				major = ((group = groups["major"]).Success && !string.IsNullOrEmpty(gitVal = group.Value)) ? int.Parse(gitVal) : 0;
				minor = ((group = groups["minor"]).Success && !string.IsNullOrEmpty(gitVal = group.Value)) ? int.Parse(gitVal) : 0;
				build = ((group = groups["build"]).Success && !string.IsNullOrEmpty(gitVal = group.Value)) ? int.Parse(gitVal) : 0;
				revision = ((group = groups["revision"]).Success && !string.IsNullOrEmpty(gitVal = group.Value)) ? int.Parse(gitVal) : 0;
				hash = (group = groups["hash"]).Success ? group.Value : string.Empty;
			}
			else
			{
				major = Config.MajorVersion;
				minor = Config.MinorVersion;
				build = ((Config.ReleaseYearMonth.Year - 2000) * 100) + Config.ReleaseYearMonth.Month;
				hash = string.Empty;

				DateTime today = DateTime.Today;
				int month = ((today.Year - Config.RevisionStartYearMonth.Year) * 12) + (today.Month - Config.RevisionStartYearMonth.Month) + 1;
				int monthsAsQuarters = ((today.Year - Config.CountQuartersFromYearMonth.Year) * 12) + (today.Month - Config.CountQuartersFromYearMonth.Month) + 1;
				if (monthsAsQuarters > 0)
				{
					// This revision mechanism was moving much too quickly, so allow the
					// option to increment by quarter instead of month. For quarter increments,
					// days 1-31 are the first month, 34-64 are the second month, and 67-97 are
					// the third month in the quarter. Months before quarter counting began are
					// added to the quarter count, giving sequential version numbers.
					revision = ((month - monthsAsQuarters) + (monthsAsQuarters + 2) / 3) * 100;
					switch ((monthsAsQuarters - 1) % 3)
					{
						case 1:
							revision += 33;
							break;
						case 2:
							revision += 66;
							break;
					}
				}
				else
				{
					revision = month * 100;
				}
				revision += today.Day;
			}

			string yearMonthString = string.Format("{0:yyyy-MM}", Config.ReleaseYearMonth);

			FileInfo lastGeneratedXml = new FileInfo(templateSettings.LastGenerated);
			if (lastGeneratedXml.Exists)
			{
				// Read the last time the files were processed and short circuit generation if nothing has changed.
				bool upToDate = false;
				using (StreamReader streamReader = lastGeneratedXml.OpenText())
				{
					using (XmlReader reader = XmlReader.Create(streamReader))
					{
						while (reader.Read())
						{
							if (reader.NodeType == XmlNodeType.Element)
							{
								upToDate = reader.GetAttribute("major") == major.ToString() &&
									reader.GetAttribute("minor") == minor.ToString() &&
									reader.GetAttribute("build") == build.ToString() &&
									reader.GetAttribute("revision") == revision.ToString() &&
									reader.GetAttribute("hash") == hash &&
									reader.GetAttribute("yearMonth") == yearMonthString &&
									reader.GetAttribute("buildType") == Config.ReleaseType &&
									reader.GetAttribute("configChange") == versionConfig.LastWriteTimeUtc.ToString(xmlDateFormat);
								break;
							}
						}
					}
				}
				if (upToDate)
				{
					Console.WriteLine(statusPrefix + "Generated version files already up to date.");
					return 0;
				}
			}

			foreach (TemplateElement template in templateSettings.Templates)
			{
				FileInfo outputInfo = new FileInfo(template.Output);
				object[] replacements = new object[8];
				int index = template.Major;
				if (index >= 0 && index < 8) replacements[index] = major;
				index = template.Minor;
				if (index >= 0 && index < 8) replacements[index] = minor;
				index = template.Build;
				if (index >= 0 && index < 8) replacements[index] = build;
				index = template.Revision;
				if (index >= 0 && index < 8) replacements[index] = revision;
				index = template.Hash;
				if (index >= 0 && index < 8) replacements[index] = hash;
				index = template.YearMonth;
				if (index >= 0 && index < 8) replacements[index] = yearMonthString;
				index = template.BuildType;
				if (index >= 0 && index < 8) replacements[index] = Config.ReleaseType;
				index = template.Warning;
				if (index >= 0 && index < 8) replacements[index] = generatedWarning;

				using (StreamWriter writer = outputInfo.CreateText())
				{
					writer.Write(string.Format(template.Content, replacements));
				}

				Console.WriteLine(statusPrefix + "Generated " + template.Output  + ".");
			}

			// We checked this earlier but don't want to rewrite it until everything else succeeds.
			using (StreamWriter writer = lastGeneratedXml.CreateText())
			{
				writer.WriteLine(string.Format("<version major='{0}' minor='{1}' build='{2}' revision='{3}' hash='{4}' yearMonth='{5}' buildType='{6}' configChange='{7}' />", major, minor, build, revision, hash, yearMonthString, Config.ReleaseType, versionConfig.LastWriteTimeUtc.ToString(xmlDateFormat)));
			}
			Console.WriteLine(statusPrefix + "Generated " + templateSettings.LastGenerated + ".");

			Console.WriteLine("VersionGenerator.exe finished successfully.");
			return 0;
		}
	}
}
