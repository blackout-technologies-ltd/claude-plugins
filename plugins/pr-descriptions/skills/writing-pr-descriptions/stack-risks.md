# Risk checks by stack

Diff these against the base and report each that changed, or "no change" for the ones reviewers care about most (bold).

| Stack | Check |
|---|---|
| Android | **Merged manifest of the prod release variant** (permissions, receivers, services, `exported`): compare `app/build/intermediates/merged_manifest/<variant>/AndroidManifest.xml` built on base and head, or at least `git diff` every `AndroidManifest.xml`. Dependency versions (`libs.versions.toml`, `build.gradle`). Room schema / DB version. `minSdk`/`targetSdk`. ProGuard/R8 rules. |
| iOS | **Entitlements** and **Info.plist** (usage strings, background modes, ATS). Marketing version + build number in `project.pbxproj`. New targets, frameworks, SPM/Pods. Provisioning profiles/certs. App group / keychain group changes. |
| Laravel | **Migrations**: list each; flag destructive ones (drop/rename column) and ones that alter big tables (`org_events`, `phone_home_logs`, `devices`) since they lock. New env vars / `config/` keys. Routes added or removed (API version prefix). Queue/job signature changes (jobs already queued must still deserialize). Scheduled commands. `composer.lock` changes. Policies/permissions. |
| Go | New env vars / flags. `go.mod` changes. Webhook or API payload shape the backend consumes. Behaviour on restart. |
| Terraform | Resources **destroyed or replaced** in the plan (state which workspaces/regions). IAM changes. Anything needing a manual apply order. |
| dbt | Models whose grain or columns change (downstream dashboards). Full-refresh needed? Cost of the new SQL on BigQuery. |
| Any | API/payload shape changes another repo consumes (mobile ↔ backend ↔ fleet-worker): name the consumer and whether old clients still work. |
