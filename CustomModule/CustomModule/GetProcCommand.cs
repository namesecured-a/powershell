using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace CustomModule
{
    [Cmdlet(VerbsCommon.Get ,"Proc")]
    public class GetProcCommand : Cmdlet
    {
        protected override void ProcessRecord()
        {
            Process[] processes = Process.GetProcesses();


            WriteObject(processes, true);
        }
    }
}
