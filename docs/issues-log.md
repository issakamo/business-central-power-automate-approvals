# Issues Log: Exception Approvals and Notifications

| ID | Date | Issue | Cause | Resolution | Status |
|---|---|---|---|---|---|
| I-001 | 2026-11-16 | PCX 1.0.0.0 symbol download from the Dev sandbox fails: Tests-TestLibraries 28.0.0.0 not found. | PCX shipped its tests inside the main app, so the main app depended on test libraries. Tests-TestLibraries is not published in the online sandbox. | Split PCX into app and test projects (D-012). PCX 1.1.0.0 installed in the Dev sandbox and the container. | Resolved |
| I-002 | 2026-11-16 | PCX test app 1.1.0.0 fails to publish to the container: AL1024, symbols for PCX 1.1.0.0 not found, although PCX 1.1.0.0 is installed there. | Not yet found. | Parked; fix before merging the `split-test-app` branch in the PCX repo. | Open |
| I-003 | 2026-11-16 | WHX 1.0.0.0 depends on Library Assert, so it cannot be installed in Production. | Tests inside the main app (same as I-001). | Split WHX into app and test projects before the Production deployment (D-012). | Open |
