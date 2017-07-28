﻿using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using MetroFramework.Forms;
using System.Net.Http;
using System.IO;
using WindowsManufacturingStudio.ViewModels;

namespace WindowsManufacturingStudio
{
    public partial class FormCreateBootWinPE : MetroForm
    {
        public FormCreateBootWinPE(MetroForm Caller, string RootDir)
        {
            InitializeComponent();

            this.caller = Caller;
            this.rootDir = RootDir;
        }

        private MetroForm caller;

        private ConfigurationViewModel conf;

        private string rootDir;

        private string getConfPath(int index)
        {
            string confPath = this.rootDir + "\\BootImages";

            confPath += index == 0 ? "\\Multicast\\config.xml" : "\\FFU\\config.xml";

            return confPath;
        }

        private void loadConf(string confPath)
        {
            string confXml = "";

            using (FileStream stream = new FileStream(confPath, FileMode.Open, FileAccess.Read, FileShare.Read))
            {
                using (StreamReader reader = new StreamReader(stream))
                {
                    confXml = reader.ReadToEnd();
                }
            }

            this.conf = Utility.XmlDeserialize(confXml, typeof(ConfigurationViewModel), null, "utf-8") as ConfigurationViewModel;
        }

        private void writeConf(string confPath)
        {
            string confXml = Utility.XmlSerialize(this.conf, null, "utf-8");

            using (FileStream stream = new FileStream(confPath, FileMode.Create, FileAccess.ReadWrite, FileShare.ReadWrite))
            {
                using (StreamWriter writer = new StreamWriter(stream, Encoding.UTF8))
                {
                    writer.Write(confXml);
                }
            }
        }

        private bool validateConf(ConfigurationViewModel conf)
        {
            return false;
        }

        private void setControlValuesFromConf(ConfigurationViewModel config)
        {
            this.metroTextBoxImageServerAddress.Text = config.ImageServerAddress;
            this.metroTextBoxImageServerPassword.Text = config.ImageServerPassword;
            this.metroTextBoxImageServerUsername.Text = config.ImageServerUserName;
            this.metroTextBoxWDSAPIURL.Text = config.WDSApiServicePoint;
        }

        private void setConfValuesFromControl(ConfigurationViewModel config)
        {
            config.ImageServerAddress = this.metroTextBoxImageServerAddress.Text;
            config.ImageServerPassword = this.metroTextBoxImageServerPassword.Text;
            config.ImageServerUserName = this.metroTextBoxImageServerUsername.Text;
            config.WDSApiServicePoint = this.metroTextBoxWDSAPIURL.Text;
        }

        private void metroTileBack_Click(object sender, EventArgs e)
        {
            this.Close();
        }

        private void metroTileCreate_Click(object sender, EventArgs e)
        {
            if (String.IsNullOrEmpty(this.metroTextBoxOutputLocation.Text))
            {
                MessageBox.Show("Output Location is required!", "Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (String.IsNullOrEmpty(this.metroTextBoxImageServerAddress.Text))
            {
                MessageBox.Show("Image Server Address is required!", "Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (String.IsNullOrEmpty(this.metroTextBoxWDSAPIURL.Text))
            {
                MessageBox.Show("WDS API URL is required!", "Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            this.setConfValuesFromControl(this.conf);

            string confPath = this.getConfPath(this.metroComboBoxImageType.SelectedIndex);

            this.writeConf(confPath);

            string architecture = this.metroRadioButtonX86.Checked ? "x86" : "amd64";
            string imageType = this.metroComboBoxImageType.SelectedIndex == 0 ? "multicast" : "ffu";
            string outputDir = this.metroTextBoxOutputLocation.Text;
            string peScriptDir = confPath.Substring(0, confPath.LastIndexOf("\\"));

            string scriptFullPath = this.rootDir + "\\BootImages\\MakePEImage.ps1";

            string argsTemp = "-ExecutionPolicy ByPass -NoExit -File \"{0}\" -Architecture \"{1}\" -ImageType \"{2}\" -OutputDir \"{3}\" -PEScriptDir \"{4}\"";

            string arguments = String.Format(argsTemp, scriptFullPath, architecture, imageType, outputDir, peScriptDir);

            Utility.StartProcess("PowerShell", arguments, true, true, false);
        }

        private void metroButtonBrowse_Click(object sender, EventArgs e)
        {
            if (this.folderBrowserDialogOutputLocation.ShowDialog() == DialogResult.OK)
            {
                this.metroTextBoxOutputLocation.Text = this.folderBrowserDialogOutputLocation.SelectedPath;
            }
        }

        private void FormCreateBootWinPE_FormClosing(object sender, FormClosingEventArgs e)
        {
            if (this.caller != null)
            {
                e.Cancel = true;
                this.caller.Visible = true;
                this.Visible = false;
            }
        }

        private void metroToggleShowPassword_CheckedChanged(object sender, EventArgs e)
        {
            this.metroTextBoxImageServerPassword.UseSystemPasswordChar = !this.metroToggleShowPassword.Checked;
            this.metroTextBoxImageServerPassword.PasswordChar = Char.MinValue;
            this.metroTextBoxImageServerPassword.Refresh();
        }

        private void metroButtonTest_Click(object sender, EventArgs e)
        {
            string url = this.metroTextBoxWDSAPIURL.Text;

            if (String.IsNullOrEmpty(url))
            {
                MessageBox.Show("WDS API URL is required!", "Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            try
            {
                HttpClient client = new HttpClient();

                client.GetStringAsync(url).ContinueWith(t =>
                {
                    if (t.IsFaulted)
                    {
                        MessageBox.Show(t.Exception.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    }
                    else
                    {

                        MessageBox.Show(t.Result, "Information", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                });
            }
            catch (Exception ex)
            {

                MessageBox.Show(ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }

        }

        private void FormCreateBootWinPE_Load(object sender, EventArgs e)
        {
            if (this.metroComboBoxImageType.SelectedIndex < 0)
            {
                this.metroComboBoxImageType.SelectedIndex = 0;
            }

            if (this.conf == null)
            {
                string confPath = this.getConfPath(this.metroComboBoxImageType.SelectedIndex);

                if (!File.Exists(confPath))
                {
                    this.conf = new ConfigurationViewModel();
                    this.writeConf(confPath);
                }

                this.loadConf(confPath);
            }

            this.setControlValuesFromConf(this.conf);
        }

        private void metroComboBoxImageType_SelectedIndexChanged(object sender, EventArgs e)
        {
            string confPath = this.getConfPath(this.metroComboBoxImageType.SelectedIndex);

            if (!File.Exists(confPath))
            {
                this.conf = new ConfigurationViewModel();
                this.writeConf(confPath);
            }

            this.loadConf(confPath);
        }
    }
}