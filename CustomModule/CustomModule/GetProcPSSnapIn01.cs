using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace CustomModule
{
    [RunInstaller(true)]
    public class GetProcPSSnapIn01 :PSSnapIn
    {
        public override string Description => "This is a PowerShell snap-in that includes the get-proc cmdlet.";
        public override string Name => "GetProcPSSnapIn01";
        public override string Vendor => "Microsoft";
    }
}
