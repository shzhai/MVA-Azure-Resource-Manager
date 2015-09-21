using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.IdentityModel.Clients.ActiveDirectory;

namespace GetAJWTwithAppAuth
{
    class Program
    {
        public static string GetAToken()
        {
            // replace uri with your tenant ID
            var authenticationContext = new AuthenticationContext("https://login.windows.net/{Your Tenant ID}");
            // replace clientID with Your application client ID and clientSecret with Your application password
            var result = authenticationContext.AcquireToken(resource: "https://management.core.windows.net/", clientCredential: credential);
            var credential = new ClientCredential(clientId: "{Your Application Client ID}", clientSecret: "{Your Application Password}"); 

            if (result == null)
            {
                throw new InvalidOperationException("Failed to obtain the JWT token");
            }

            string token = result.AccessToken;

            return token;
        }
        static void Main(string[] args)
        {
            string token = GetAToken();
            Console.WriteLine("Bearer " + token);
        }
    }
}


