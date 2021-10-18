DLConversionV2 ReadMe File.

*Sample DL Migrations

-Migrate a distribution list without needing Exchange on-premises or enabling hybrid mail flow.  Allow ad connect to trigger as part of migration to speed up process.

$onPremCred = get-credential
$cloudCred = get-credential

start-distributionListMigration -groupSMTPAddress test@domain.com -globalCatalogServer gc.domain.com -activeDirectoryCredential $onPremCred -asdConnectServer adconnect.domain.com -aadConnectCredential $onPremCred -exchangeOnlineCredential $cloudCred -logFolderPath c:\temp -dnNoSyncOU "OU=something,dc=domain,dc=com"

-Migrate a distribution list using Exchange on premsies and enabling hybrid mail flow.  Allow ad connect to trigger as part of migration to speed up process.

start-distributionListMigration -groupSMTPAddress test@domain.com -globalCatalogServer gc.domain.com -activeDirectoryCredential $onPremCred -asdConnectServer adconnect.domain.com -aadConnectCredential $onPremCred -exchangeServer exchange.domain.com -exchangeCredential $onPremCred -exchangeOnlineCredential $cloudCred -logFolderPath c:\temp -dnNoSyncOU "OU=something,dc=domain,dc=com"

-Migrate a distribution list using Exchange on premsies and enabling hybrid mail flow.  Allow ad connect to trigger as part of migration to speed up process.  At the end of the mirgation trigger an upgrade to a modern / universal / office 365 group.

start-distributionListMigration -groupSMTPAddress test@domain.com -globalCatalogServer gc.domain.com -activeDirectoryCredential $onPremCred -asdConnectServer adconnect.domain.com -aadConnectCredential $onPremCred -exchangeServer exchange.domain.com -exchangeCredential $onPremCred -exchangeOnlineCredential $cloudCred -logFolderPath c:\temp -dnNoSyncOU "OU=something,dc=domain,dc=com" -triggerUpgradeToOffice365Group


*Information regarding the usage of the DLConversionV2 module can be found in the following blog posts.

*Introduction to the Distribution List Migration Module v2
https://timmcmic.wordpress.com/2021/04/25/4116/

*Preparing to use the Distrbution List Migration Module v2
https://timmcmic.wordpress.com/2021/04/26/office-365-distribution-list-migrations-version-2-0-part-2/

*Using the Distribution List Migration Module v2 for Sample Migrations
https://timmcmic.wordpress.com/2021/04/26/office-365-distribution-list-migrations-version-2-0-part-3-2/

*Retaining the Original Distribution Group Post Migration
https://timmcmic.wordpress.com/2021/04/27/office-365-distribution-list-migrations-version-2-0-part-4/

*Gathering Advanced Dependencies for a Group to be Migrated
https://timmcmic.wordpress.com/2021/04/27/office-365-distribution-list-migrations-version-2-0-part-5/

*How Does the Module Track Distribution Lists that have been Migrated
https://timmcmic.wordpress.com/2021/04/28/office-365-distribution-list-migrations-version-2-0-part-6/

*Enabling Hybrid Mail Flow for Migrated Distribution Lists
https://timmcmic.wordpress.com/2021/04/28/office-365-distribution-list-migrations-version-2-0-part-7/

*Lessons from customer implementations - module improvements.
https://timmcmic.wordpress.com/2021/09/01/office-365-distribution-list-migration-version-2-0-part-8/

*How to perform single host batch migrations.
https://timmcmic.wordpress.com/2021/09/02/office-365-distribution-list-migrations-version-2-0-part-9/

*Improvements and code fixes in version 2.4.x
https://timmcmic.wordpress.com/2021/09/27/office-365-distribution-list-migration-version-2-0-part-10/



