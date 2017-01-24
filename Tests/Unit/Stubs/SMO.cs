// Stubs for the namespace Microsoft.SqlServer.Management.Smo. Used for mocking in tests.

using System;
using System.Collections.Generic;
using System.Security;
using System.Runtime.InteropServices;

namespace Microsoft.SqlServer.Management.Smo
{
    #region Public Enums

    // TypeName: Microsoft.SqlServer.Management.Smo.LoginCreateOptions
    // Used by:
    //  MSFT_xSQLServerLogin.Tests.ps1
    public enum LoginCreateOptions
    {
        None = 0,
        IsHashed = 1,
        MustChange = 2
    }
    
    // TypeName: Microsoft.SqlServer.Management.Smo.LoginType
    // BaseType: Microsoft.SqlServer.Management.Smo.ScriptNameObjectBase
    // Used by: 
    //  MSFT_xSQLServerLogin
    public enum LoginType
    {
        AsymmetricKey = 4,
        Certificate = 3,
        ExternalGroup = 6,
        ExternalUser = 5,
        SqlLogin = 2,
        WindowsGroup = 1,
        WindowsUser = 0,
        Unknown = -1    // Added for verification (mock) purposes, to verify that a login type is passed  
    }
    
    // TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityReplicaFailoverMode
    // Used by: 
    //  MSFT_xSQLAOGroupEnsure.Tests
    public enum AvailabilityReplicaFailoverMode
    {
        Automatic,
        Manual,
        Unknown
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityReplicaAvailabilityMode
    // Used by: 
    //  MSFT_xSQLAOGroupEnsure.Tests
    public enum AvailabilityReplicaAvailabilityMode
    {
        AsynchronousCommit,
        SynchronousCommit,
        Unknown
    }

    #endregion Public Enums

    #region Public Classes

    public class Globals
    {
        // Static property that is switched on or off by tests if data should be mocked (true) or not (false).
        public static bool GenerateMockData = false;
    }

    // Typename: Microsoft.SqlServer.Management.Smo.ObjectPermissionSet
    // BaseType: Microsoft.SqlServer.Management.Smo.PermissionSetBase
    // Used by: 
    //  xSQLServerEndpointPermission.Tests.ps1
    public class ObjectPermissionSet 
    {
        public ObjectPermissionSet(){}

        public ObjectPermissionSet(
            bool connect )
        {
            this.Connect = connect; 
        } 
    
        public bool Connect = false;
    }
    
    // TypeName: Microsoft.SqlServer.Management.Smo.ServerPermissionSet
    // BaseType: Microsoft.SqlServer.Management.Smo.PermissionSetBase
    // Used by: 
    //  xSQLServerPermission.Tests.ps1
    public class ServerPermissionSet 
    {
        public ServerPermissionSet(){}

        public ServerPermissionSet(
            bool alterAnyAvailabilityGroup, 
            bool alterAnyEndPoint,
            bool connectSql,  
            bool viewServerState )
        {
            this.AlterAnyAvailabilityGroup = alterAnyAvailabilityGroup; 
            this.AlterAnyEndPoint = alterAnyEndPoint;
            this.ConnectSql = connectSql;
            this.ViewServerState = viewServerState;
        } 
    
        public bool AlterAnyAvailabilityGroup = false;
        public bool AlterAnyEndPoint = false;
        public bool ConnectSql = false;
        public bool ViewServerState = false;
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.ServerPermissionInfo
    // BaseType: Microsoft.SqlServer.Management.Smo.PermissionInfo
    // Used by: 
    //  xSQLServerPermission.Tests.ps1
    public class ServerPermissionInfo 
    {
        public ServerPermissionInfo()
        {
            Microsoft.SqlServer.Management.Smo.ServerPermissionSet[] permissionSet = { new Microsoft.SqlServer.Management.Smo.ServerPermissionSet() };
            this.PermissionType = permissionSet;
        }

        public ServerPermissionInfo( 
            Microsoft.SqlServer.Management.Smo.ServerPermissionSet[] permissionSet )
        {
            this.PermissionType = permissionSet;
        }
        
        public Microsoft.SqlServer.Management.Smo.ServerPermissionSet[] PermissionType;
        public string PermissionState = "Grant";
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.DatabasePermissionSet
    // BaseType: Microsoft.SqlServer.Management.Smo.PermissionSetBase
    // Used by: 
    //  xSQLServerDatabasePermission.Tests.ps1
    public class DatabasePermissionSet 
    {
        public DatabasePermissionSet(){}

        public DatabasePermissionSet( bool connect, bool update )
        {
            this.Connect = connect; 
            this.Update = update;
        } 
    
        public bool Connect = false;
        public bool Update = false;
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo
    // BaseType: Microsoft.SqlServer.Management.Smo.PermissionInfo
    // Used by: 
    //  xSQLServerDatabasePermission.Tests.ps1
    public class DatabasePermissionInfo 
    {
        public DatabasePermissionInfo()
        {
            Microsoft.SqlServer.Management.Smo.DatabasePermissionSet[] permissionSet = { new Microsoft.SqlServer.Management.Smo.DatabasePermissionSet() };
            this.PermissionType = permissionSet;
        }

        public DatabasePermissionInfo( Microsoft.SqlServer.Management.Smo.DatabasePermissionSet[] permissionSet )
        {
            this.PermissionType = permissionSet;
        }
        
        public Microsoft.SqlServer.Management.Smo.DatabasePermissionSet[] PermissionType;
        public string PermissionState = "Grant";
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.Server
    // BaseType: Microsoft.SqlServer.Management.Smo.SqlSmoObject
    // Used by: 
    //  xSQLServerPermission
    //  MSFT_xSQLServerLogin
    public class Server 
    { 
        public string MockGranteeName;

        public string Name;
        public string DisplayName;
        public string InstanceName;
        public string ServiceName;
        public bool IsClustered = false;
        public bool IsHadrEnabled = false;

        public Server(){} 

        public Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[] EnumServerPermissions( string principal, Microsoft.SqlServer.Management.Smo.ServerPermissionSet permissionSetQuery ) 
        { 
            List<Microsoft.SqlServer.Management.Smo.ServerPermissionInfo> listOfServerPermissionInfo = new List<Microsoft.SqlServer.Management.Smo.ServerPermissionInfo>();
            
            if( Globals.GenerateMockData ) {
                Microsoft.SqlServer.Management.Smo.ServerPermissionSet[] permissionSet = { 
                    new Microsoft.SqlServer.Management.Smo.ServerPermissionSet( true, false, false, false ),
                    new Microsoft.SqlServer.Management.Smo.ServerPermissionSet( false, true, false, false ),
                    new Microsoft.SqlServer.Management.Smo.ServerPermissionSet( false, false, true, false ),
                    new Microsoft.SqlServer.Management.Smo.ServerPermissionSet( false, false, false, true ) };

                listOfServerPermissionInfo.Add( new Microsoft.SqlServer.Management.Smo.ServerPermissionInfo( permissionSet ) );
            } else {
                listOfServerPermissionInfo.Add( new Microsoft.SqlServer.Management.Smo.ServerPermissionInfo() );
            }

            Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[] permissionInfo = listOfServerPermissionInfo.ToArray();

            return permissionInfo;
        }

        public void Grant( Microsoft.SqlServer.Management.Smo.ServerPermissionSet permission, string granteeName )
        {
            if( granteeName != this.MockGranteeName ) 
            {
                string errorMessage = "Expected to get granteeName == '" + this.MockGranteeName + "'. But got '" + granteeName + "'";
                throw new System.ArgumentException(errorMessage, "granteeName");
            }
        }

        public void Revoke( Microsoft.SqlServer.Management.Smo.ServerPermissionSet permission, string granteeName )
        {
            if( granteeName != this.MockGranteeName ) 
            {
                string errorMessage = "Expected to get granteeName == '" + this.MockGranteeName + "'. But got '" + granteeName + "'";
                throw new System.ArgumentException(errorMessage, "granteeName");
            }
        }
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.Login
    // BaseType: Microsoft.SqlServer.Management.Smo.ScriptNameObjectBase
    // Used by: 
    //  MSFT_xSQLServerLogin
    public class Login 
    {
        private bool _mockPasswordPassed = false;

        public string Name;
        public LoginType LoginType = LoginType.Unknown;
        public bool MustChangePassword = false;
        public bool PasswordPolicyEnforced = false;
        public bool PasswordExpirationEnabled = false;

        public string MockName;
        public LoginType MockLoginType;

        public Login( Server server, string name )
        {
            this.Name = name;
        }
        
        public Login( Object server, string name )
        {
            this.Name = name;
        }
        
        public void Alter()
        {
            if( !( String.IsNullOrEmpty(this.MockName) ) )
            {
                if(this.MockName != this.Name)
                {
                    throw new Exception();
                }
            }

            if( !( String.IsNullOrEmpty(this.MockLoginType.ToString()) ) )
            {
                if( this.MockLoginType != this.LoginType )
                {
                    throw new Exception(this.MockLoginType.ToString());
                }
            }
        }
        
        public void ChangePassword( SecureString secureString )
        {
            IntPtr valuePtr = IntPtr.Zero;
            try
            {
                valuePtr = Marshal.SecureStringToGlobalAllocUnicode(secureString);            
                if ( Marshal.PtrToStringUni(valuePtr) == "pw" )
                {                    
                    throw new FailedOperationException (
                        "FailedOperationException",
                        new SmoException (
                            "SmoException",
                            new SqlServerManagementException (
                                "SqlServerManagementException",
                                new Exception (
                                    "Password validation failed. The password does not meet Windows policy requirements because it is too short."
                                )
                            )
                        )
                    );
                }
                else if ( Marshal.PtrToStringUni(valuePtr) == "reused" )
                {
                    throw new FailedOperationException ();
                }
                else if ( Marshal.PtrToStringUni(valuePtr) == "other" )
                {
                    throw new Exception ();
                }
            }
            finally
            {
                Marshal.ZeroFreeGlobalAllocUnicode(valuePtr);
            }
        }
        
        public void Create()
        {
            if( this.LoginType == LoginType.Unknown ) {
                throw new System.Exception( "Called Create() method without a value for LoginType." );
            }

            if( this.LoginType == LoginType.SqlLogin && _mockPasswordPassed != true ) {
                throw new System.Exception( "Called Create() method for the LoginType 'SqlLogin' but called with the wrong overloaded method. Did not pass the password with the Create() method." );
            }

            if( !( String.IsNullOrEmpty(this.MockName) ) )
            {
                if(this.MockName != this.Name)
                {
                    throw new Exception();
                }
            }

            if( !( String.IsNullOrEmpty(this.MockLoginType.ToString()) ) )
            {
                if( this.MockLoginType != this.LoginType )
                {
                    throw new Exception(this.MockLoginType.ToString());
                }
            }
        }

        public void Create( SecureString secureString )
        {
            _mockPasswordPassed = true;

            this.Create();
        }

        public void Create( SecureString password, LoginCreateOptions options  )
        {
            IntPtr valuePtr = IntPtr.Zero;
            try
            {
                valuePtr = Marshal.SecureStringToGlobalAllocUnicode(password);
                if ( Marshal.PtrToStringUni(valuePtr) == "pw" )
                {                    
                    throw new FailedOperationException (
                        "FailedOperationException",
                        new SmoException (
                            "SmoException",
                            new SqlServerManagementException (
                                "SqlServerManagementException",
                                new Exception (
                                    "Password validation failed. The password does not meet Windows policy requirements because it is too short."
                                )
                            )
                        )
                    );
                }
                else if ( this.Name == "Existing" )
                {
                    throw new FailedOperationException ( "The login already exists" );
                }
                else if ( this.Name == "Unknown" )
                {
                    throw new Exception ();
                }
                else
                {                    
                    _mockPasswordPassed = true;
                    
                    this.Create();
                }
            }
            finally
            {
                Marshal.ZeroFreeGlobalAllocUnicode(valuePtr);
            }
        }

        public void Drop()
        {
            if( !( String.IsNullOrEmpty(this.MockName) ) )
            {
                if(this.MockName != this.Name)
                {
                    throw new Exception();
                }
            }

            if( !( String.IsNullOrEmpty(this.MockLoginType.ToString()) ) )
            {
                if( this.MockLoginType != this.LoginType )
                {
                    throw new Exception(this.MockLoginType.ToString());
                }
            }
        }
    }
	
	// TypeName: Microsoft.SqlServer.Management.Smo.ServerRole
    // BaseType: Microsoft.SqlServer.Management.Smo.ScriptNameObjectBase
    // Used by: 
    //  MSFT_xSQLServerRole
    public class ServerRole 
    {
        public ServerRole( Server server, string name ) {
            this.Name = name;
        } 

        public ServerRole( Object server, string name ) {
            this.Name = name;
        } 
            
        public string Name;
    }


	// TypeName: Microsoft.SqlServer.Management.Smo.Database
    // BaseType: Microsoft.SqlServer.Management.Smo.ScriptNameObjectBase
    // Used by: 
    //  MSFT_xSQLServerDatabase
    //  MSFT_xSQLServerDatabasePermission
	public class Database
	{
        public string MockGranteeName;

        public Database( Server server, string name ) {
            this.Name = name;
        } 

        public Database( Object server, string name ) {
            this.Name = name;
        } 
            
        public string Name;
		
		public void Create()
        {
        }
		
		public void Drop()
        {
        }
		
        public Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[] EnumDatabasePermissions( string granteeName ) 
        { 
            List<Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo> listOfDatabasePermissionInfo = new List<Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo>();
            
            if( Globals.GenerateMockData ) {
                Microsoft.SqlServer.Management.Smo.DatabasePermissionSet[] permissionSet = { 
                    new Microsoft.SqlServer.Management.Smo.DatabasePermissionSet( true, false ),
                    new Microsoft.SqlServer.Management.Smo.DatabasePermissionSet( false, true )
                };

                listOfDatabasePermissionInfo.Add( new Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo( permissionSet ) );
            } else {
                listOfDatabasePermissionInfo.Add( new Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo() );
            }

            Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[] permissionInfo = listOfDatabasePermissionInfo.ToArray();

            return permissionInfo;
        }

        public void Grant( Microsoft.SqlServer.Management.Smo.DatabasePermissionSet permission, string granteeName )
        {
            if( granteeName != this.MockGranteeName ) 
            {
                string errorMessage = "Expected to get granteeName == '" + this.MockGranteeName + "'. But got '" + granteeName + "'";
                throw new System.ArgumentException(errorMessage, "granteeName");
            }
        }

        public void Deny( Microsoft.SqlServer.Management.Smo.DatabasePermissionSet permission, string granteeName )
        {
            if( granteeName != this.MockGranteeName ) 
            {
                string errorMessage = "Expected to get granteeName == '" + this.MockGranteeName + "'. But got '" + granteeName + "'";
                throw new System.ArgumentException(errorMessage, "granteeName");
            }
        }
	}

    // TypeName: Microsoft.SqlServer.Management.Smo.User
    // BaseType: Microsoft.SqlServer.Management.Smo.ScriptNameObjectBase
    // Used by: 
    //  xSQLServerDatabaseRole.Tests.ps1
    public class User 
    {
        public User( Server server, string name )
        {
            this.Name = name;
        } 

        public User( Object server, string name )
        {
            this.Name = name;
        }

        public string Name;
        public string Login;

        public void Create()
        {
        }

        public void Drop()
        {
        }
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.SqlServerManagementException
    // BaseType: System.Exception 
    // Used by:
    //  xSqlServerLogin.Tests.ps1
    public class SqlServerManagementException : Exception
    {
        public SqlServerManagementException () : base () {}

        public SqlServerManagementException (string message) : base (message) {}

        public SqlServerManagementException (string message, Exception inner) : base (message, inner) {}
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.SmoException
    // BaseType: Microsoft.SqlServer.Management.Smo.SqlServerManagementException  
    // Used by:
    //  xSqlServerLogin.Tests.ps1
    public class SmoException : SqlServerManagementException
    {
        public SmoException () : base () {}

        public SmoException (string message) : base (message) {}
        
        public SmoException (string message, SqlServerManagementException inner) : base (message, inner) {}
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.FailedOperationException
    // BaseType: Microsoft.SqlServer.Management.Smo.SmoException
    // Used by:
    //  xSqlServerLogin.Tests.ps1
    public class FailedOperationException : SmoException
    {
        public FailedOperationException () : base () {}
        
        public FailedOperationException (string message) : base (message) {}
        
        public FailedOperationException (string message, SmoException inner) : base (message, inner) {}
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroup
    // BaseType: Microsoft.SqlServer.Management.Smo.NamedSmoObject
    // Used by:
    //  xSQLServerAlwaysOnAvailabilityGroup
    public class AvailabilityGroup
    {
        public AvailabilityGroup()
        {}

        public AvailabilityGroup( Server server, string name )
        {}

        public string AutomatedBackupPreference;
        public string AvailabilityReplicas;
        public bool BasicAvailabilityGroup;
        public string FailureConditionLevel;
        public string HealthCheckTimeout;
        public string Name;
        public string PrimaryReplicaServerName;
        public string LocalReplicaRole;

        public void Alter()
        {
            if ( this.Name == "AlterFailed" )
            {
                throw new System.Exception( "Alter Availability Group failed" );
            }
        }
    }
    
    // TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityReplica
    // BaseType: Microsoft.SqlServer.Management.Smo.NamedSmoObject
    // Used by:
    //  xSQLServerAlwaysOnAvailabilityGroup
    public class AvailabilityReplica
    {
        public AvailabilityReplica()
        {}

        public AvailabilityReplica( AvailabilityGroup availabilityGroup, string name )
        {}

        public string AvailabilityMode;
        public string BackupPriority;
        public string ConnectionModeInPrimaryRole;
        public string ConnectionModeInSecondaryRole;
        public string EndpointUrl;
        public string FailoverMode;
        public string Name;
        
        public void Alter()
        {
            if ( this.Name == "AlterFailed" )
            {
                throw new System.Exception( "Alter Availability Group Replica failed" );
            }
        }

        public void Create()
        {}
    }
    #endregion Public Classes
}
