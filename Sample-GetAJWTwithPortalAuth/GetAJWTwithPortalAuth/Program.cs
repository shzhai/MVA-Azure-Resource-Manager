using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Threading;
using Microsoft.IdentityModel.Clients.ActiveDirectory;

namespace GetAJWTwithPortalAuth
{
    class Program
    {
        static void Main(string[] args)
        {
            var tenantId = "{Your Tenant ID}"; // replace with your tenant id
            var clientId = "{Your Application Client ID}"; // replace with your client id
            var authUrl = "https://login.windows.net";
            var header = GetAuthorizationHeader(tenantId, authUrl, clientId);
            Console.Write(header);
        }

        private static string GetAuthorizationHeader(string tenantId, string authUrlHost, string clientId)
        {
            AuthenticationResult result = null;
            var thread = new Thread(() =>
            {
                try
                {
                    var authUrl = String.Format(authUrlHost + "/{0}", tenantId);
                    var context = new AuthenticationContext(authUrl);
                    result = context.AcquireToken(
                        resource: "https://management.core.windows.net/",
                        clientId: clientId,
                        redirectUri: new Uri("{Your application URI}"), // replace with your application URI
                        promptBehavior: PromptBehavior.Auto);
                }
                catch (Exception threadEx)
                {
                    Console.WriteLine(threadEx.Message);
                }
            });

            thread.SetApartmentState(ApartmentState.STA);
            thread.Name = "AcquireTokenThread";
            thread.Start();
            thread.Join();

            return result.CreateAuthorizationHeader();
        }
    }
}
