// Stubs for the namespace Microsoft.SqlServer.Management.Smo. Used for mocking in tests.

using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Globalization;
using System.Security;
using System.Runtime.InteropServices;

namespace Microsoft.SqlServer.Management.Smo
{
    #region Public Enums

    // TypeName: Microsoft.SqlServer.Management.Smo.LoginCreateOptions
    // Used by:
    //  DSC_SqlServerLogin.Tests.ps1
    public enum LoginCreateOptions
    {
        None = 0,
        IsHashed = 1,
        MustChange = 2
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.LoginType
    // BaseType: Microsoft.SqlServer.Management.Smo.ScriptNameObjectBase
    // Used by:
    //  DSC_SqlServerLogin
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
    //  -
    public enum AvailabilityReplicaFailoverMode
    {
        Automatic,
        Manual,
        Unknown
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityReplicaAvailabilityMode
    // Used by:
    //  -
    public enum AvailabilityReplicaAvailabilityMode
    {
        AsynchronousCommit,
        SynchronousCommit,
        Unknown
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.EndpointType
    // Used by:
    //  SqlServerEndpoint
    public enum EndpointType
    {
        DatabaseMirroring,
        ServiceBroker,
        Soap,
        TSql
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.ProtocolType
    // Used by:
    //  SqlServerEndpoint
    public enum ProtocolType
    {
        Http,
        NamedPipes,
        SharedMemory,
        Tcp,
        Via
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.ServerMirroringRole
    // Used by:
    //  SqlServerEndpoint
    public enum ServerMirroringRole
    {
        All,
        None,
        Partner,
        Witness
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.EndpointEncryption
    // Used by:
    //  SqlServerEndpoint
    public enum EndpointEncryption
    {
        Disabled,
        Required,
        Supported
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.EndpointEncryptionAlgorithm
    // Used by:
    //  SqlServerEndpoint
    public enum EndpointEncryptionAlgorithm
    {
        Aes,
        AesRC4,
        None,
        RC4,
        RC4Aes
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
    //  SqlServerEndpointPermission.Tests.ps1
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
    //  SqlServerPermission.Tests.ps1
    public class ServerPermissionSet
    {
        public ServerPermissionSet(){}

        public ServerPermissionSet(
            bool alterAnyAvailabilityGroup,
            bool alterAnyEndpoint,
            bool connectSql,
            bool viewServerState )
        {
            this.AlterAnyAvailabilityGroup = alterAnyAvailabilityGroup;
            this.AlterAnyEndpoint = alterAnyEndpoint;
            this.ConnectSql = connectSql;
            this.ViewServerState = viewServerState;
        }

        public bool AlterAnyAvailabilityGroup = false;
        public bool AlterAnyEndpoint = false;
        public bool ConnectSql = false;
        public bool ViewServerState = false;
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.ServerPermissionInfo
    // BaseType: Microsoft.SqlServer.Management.Smo.PermissionInfo
    // Used by:
    //  SqlServerPermission.Tests.ps1
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
    //  SqlDatabasePermission.Tests.ps1
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
    //  SqlDatabasePermission.Tests.ps1
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
    //  SqlServerPermission
    //  DSC_SqlServerLogin
    public class Server
    {
        public string MockGranteeName;

        public AvailabilityGroupCollection AvailabilityGroups = new AvailabilityGroupCollection();
        public ServerConnection ConnectionContext;
        public string ComputerNamePhysicalNetBIOS;
        public DatabaseCollection Databases = new DatabaseCollection();
        public string DisplayName;
        public string DomainInstanceName;
        public EndpointCollection Endpoints = new EndpointCollection();
        public string FilestreamLevel = "Disabled";
        public string InstanceName;
        public string ServiceName;
        public string DefaultFile;
        public string DefaultLog;
        public string BackupDirectory;
        public bool IsClustered = false;
        public bool IsHadrEnabled = false;
        public bool IsMemberOfWsfcCluster = false;
        public Hashtable Logins = new Hashtable();
        public string Name;
        public string NetName;
        public Hashtable Roles = new Hashtable();
        public Hashtable Version = new Hashtable();

        public Server(){}
        public Server(string name)
        {
            this.Name = name;
        }

        public Server Clone()
        {
            return new Server()
            {
                MockGranteeName = this.MockGranteeName,
                AvailabilityGroups = this.AvailabilityGroups,
                ConnectionContext = this.ConnectionContext,
                ComputerNamePhysicalNetBIOS = this.ComputerNamePhysicalNetBIOS,
                Databases = this.Databases,
                DisplayName = this.DisplayName,
                DomainInstanceName = this.DomainInstanceName,
                Endpoints = this.Endpoints,
                FilestreamLevel = this.FilestreamLevel,
                InstanceName = this.InstanceName,
                IsClustered = this.IsClustered,
                IsHadrEnabled = this.IsHadrEnabled,
                Logins = this.Logins,
                Name = this.Name,
                NetName = this.NetName,
                Roles = this.Roles,
                ServiceName = this.ServiceName,
                Version = this.Version
            };
        }

        public Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[] EnumServerPermissions( string principal, Microsoft.SqlServer.Management.Smo.ServerPermissionSet permissionSetQuery )
        {
            Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[] permissionInfo = null;
            List<Microsoft.SqlServer.Management.Smo.ServerPermissionInfo> listOfServerPermissionInfo = null;

            if( Globals.GenerateMockData ) {
                listOfServerPermissionInfo = new List<Microsoft.SqlServer.Management.Smo.ServerPermissionInfo>();

                Microsoft.SqlServer.Management.Smo.ServerPermissionSet[] permissionSet = {
                    // AlterAnyEndpoint is set to false to test when permissions are missing.

                    // AlterAnyAvailabilityGroup is set to true.
                    new Microsoft.SqlServer.Management.Smo.ServerPermissionSet( true, false, false, false ),
                    // ConnectSql is set to true.
                    new Microsoft.SqlServer.Management.Smo.ServerPermissionSet( false, false, true, false ),
                    // ViewServerState is set to true.
                    new Microsoft.SqlServer.Management.Smo.ServerPermissionSet( false, false, false, true ) };

                listOfServerPermissionInfo.Add( new Microsoft.SqlServer.Management.Smo.ServerPermissionInfo( permissionSet ) );
            }

            if( listOfServerPermissionInfo != null ) {
                permissionInfo = listOfServerPermissionInfo.ToArray();
            }

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
    //  DSC_SqlServerLogin
    public class Login
    {
        private bool _mockPasswordPassed = false;

        public string Name;
        public LoginType LoginType = LoginType.Unknown;
        public bool MustChangePassword = false;
        public bool PasswordPolicyEnforced = false;
        public bool PasswordExpirationEnabled = false;
        public bool IsDisabled = false;
        public string DefaultDatabase;

        public string MockName;
        public LoginType MockLoginType;

        public Login( string name )
        {
            this.Name = name;
        }

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
    //  DSC_SqlServerRole
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
    //  DSC_SqlAGDatabase
    //  DSC_SqlDatabase
    //  DSC_SqlDatabasePermission
	public class Database
	{
        public bool AutoClose = false;
        public string AvailabilityGroupName = "";
        public Certificate[] Certificates;
        public string ContainmentType = "None";
        public DatabaseEncryptionKey DatabaseEncryptionKey;
        public string DefaultFileStreamFileGroup;
        public bool EncryptionEnabled = false;
        public Hashtable FileGroups;
        public string FilestreamDirectoryName;
        public string FilestreamNonTransactedAccess = "Off";
        public int ID = 6;
        public bool IsMirroringEnabled = false;
        public DateTime LastBackupDate = DateTime.Now;
        public Hashtable LogFiles;
        public string MockGranteeName;
        public string Owner = "sa";
        public bool ReadOnly = false;
        public string RecoveryModel = "Full";
        public string UserAccess = "Multiple";


        public Database( Server server, string name ) {
            this.Name = name;
        }

        public Database( Object server, string name ) {
            this.Name = name;
        }

        public Database() {}

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
    //  SqlDatabaseRole.Tests.ps1
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
    //  SqlServerLogin.Tests.ps1
    public class SqlServerManagementException : Exception
    {
        public SqlServerManagementException () : base () {}

        public SqlServerManagementException (string message) : base (message) {}

        public SqlServerManagementException (string message, Exception inner) : base (message, inner) {}
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.SmoException
    // BaseType: Microsoft.SqlServer.Management.Smo.SqlServerManagementException
    // Used by:
    //  SqlServerLogin.Tests.ps1
    public class SmoException : SqlServerManagementException
    {
        public SmoException () : base () {}

        public SmoException (string message) : base (message) {}

        public SmoException (string message, SqlServerManagementException inner) : base (message, inner) {}
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.FailedOperationException
    // BaseType: Microsoft.SqlServer.Management.Smo.SmoException
    // Used by:
    //  SqlServerLogin.Tests.ps1
    public class FailedOperationException : SmoException
    {
        public FailedOperationException () : base () {}

        public FailedOperationException (string message) : base (message) {}

        public FailedOperationException (string message, SmoException inner) : base (message, inner) {}
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroup
    // BaseType: Microsoft.SqlServer.Management.Smo.NamedSmoObject
    // Used by:
    //  SqlAG
    public class AvailabilityGroup
    {
        public AvailabilityGroup()
        {}

        public AvailabilityGroup( Server server, string name )
        {}

        public string AutomatedBackupPreference;
        public AvailabilityDatabaseCollection AvailabilityDatabases = new AvailabilityDatabaseCollection();
        public AvailabilityReplicaCollection AvailabilityReplicas = new AvailabilityReplicaCollection();
        public bool BasicAvailabilityGroup;
        public bool DatabaseHealthTrigger;
        public bool DtcSupportEnabled;
        public string FailureConditionLevel;
        public string HealthCheckTimeout;
        public string Name;
        public string PrimaryReplicaServerName;
        public string LocalReplicaRole = "Secondary";

        public void Alter()
        {
            if ( this.Name == "AlterFailed" )
            {
                throw new System.Exception( "Alter Availability Group failed" );
            }
        }

        public AvailabilityGroup Clone()
        {
            return new AvailabilityGroup()
            {
                AutomatedBackupPreference = this.AutomatedBackupPreference,
                AvailabilityDatabases = this.AvailabilityDatabases,
                AvailabilityReplicas = this.AvailabilityReplicas,
                BasicAvailabilityGroup = this.BasicAvailabilityGroup,
                DatabaseHealthTrigger = this.DatabaseHealthTrigger,
                DtcSupportEnabled = this.DtcSupportEnabled,
                FailureConditionLevel = this.FailureConditionLevel,
                HealthCheckTimeout = this.HealthCheckTimeout,
                Name = this.Name,
                PrimaryReplicaServerName = this.PrimaryReplicaServerName,
                LocalReplicaRole = this.LocalReplicaRole
            };
        }
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityReplica
    // BaseType: Microsoft.SqlServer.Management.Smo.NamedSmoObject
    // Used by:
    //  SqlAG
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
        public string ReadOnlyRoutingConnectionUrl;
        public System.Collections.Specialized.StringCollection ReadOnlyRoutingList;
        public string Role = "Secondary";

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

    // TypeName: Microsoft.SqlServer.Management.Common.ServerConnection
    // Used by:
    //  SqlAGDatabase
    public class ServerConnection
    {
        public string TrueLogin;

        public void Create()
        {}
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityDatabase
    // Used by:
    //  SqlAGDatabase
    public class AvailabilityDatabase
    {
        public string Name;

        public void Create() {}
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.DatabaseCollection
    // Used by:
    //  SqlAGDatabase
    public class DatabaseCollection : Collection<Database>
    {
        public Database this[string name]
        {
            get
            {
                foreach ( Database database in this )
                {
                    if ( name == database.Name )
                    {
                        return database;
                    }
                }

                return null;
            }
        }
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityReplicaCollection
    // Used by:
    //  SqlAGDatabase
    public class AvailabilityReplicaCollection : Collection<AvailabilityReplica>
    {
        public AvailabilityReplica this[string name]
        {
            get
            {
                foreach ( AvailabilityReplica availabilityReplica in this )
                {
                    if ( name == availabilityReplica.Name )
                    {
                        return availabilityReplica;
                    }
                }

                return null;
            }
        }
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.DatabaseEncryptionKey
    // Used by:
    //  SqlAGDatabase
    public class DatabaseEncryptionKey
    {
        public string EncryptorName;
        public byte[] Thumbprint;
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.Certificate
    // Used by:
    //  SqlAGDatabase
    public class Certificate
    {
        public byte[] Thumbprint;
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityDatabaseCollection
    // Used by:
    //  SqlAGDatabase
    public class AvailabilityDatabaseCollection : Collection<AvailabilityDatabase>
    {
        public AvailabilityDatabase this[string name]
        {
            get
            {
                foreach ( AvailabilityDatabase availabilityDatabase in this )
                {
                    if ( name == availabilityDatabase.Name )
                    {
                        return availabilityDatabase;
                    }
                }

                return null;
            }
        }
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupCollection
    // Used by:
    //  SqlAG
    public class AvailabilityGroupCollection : Collection<AvailabilityGroup>
    {
        public AvailabilityGroup this[string name]
        {
            get
            {
                foreach ( AvailabilityGroup availabilityGroup in this )
                {
                    if ( name == availabilityGroup.Name )
                    {
                        return availabilityGroup;
                    }
                }

                return null;
            }
        }
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
    // Used by:
    //  SqlAG
    public class Endpoint
    {
        public string Name;
        public string EndpointType;
        public Hashtable Protocol;
    }

    // TypeName: Microsoft.SqlServer.Management.Smo.EndpointCollection
    // Used by:
    //  SqlAG
    public class EndpointCollection : Collection<Endpoint>
    {
        public Endpoint this[string name]
        {
            get
            {
                foreach ( Endpoint endpoint in this )
                {
                    if ( name == endpoint.Name )
                    {
                        return endpoint;
                    }
                }

                return null;
            }
        }
    }

    #endregion Public Classes
}

namespace Microsoft.SqlServer.Management.Smo.Wmi
{
    #region Public Enums

    // TypeName: Microsoft.SqlServer.Management.Smo.Wmi.ManagedServiceType
    // Used by:
    //  DSC_SqlServiceAccount.Tests.ps1
    public enum ManagedServiceType
    {
        SqlServer = 1,

        SqlAgent = 2,

        Search = 3,

        SqlServerIntegrationService = 4,

        AnalysisServer = 5,

        ReportServer = 6,

        SqlBrowser = 7,

        NotificationServer = 8
    }

    #endregion
}
