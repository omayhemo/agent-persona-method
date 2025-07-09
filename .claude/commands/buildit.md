---
name: buildit
description: Build AP Method distribution package
---

Build the AP Method distribution package by running the build script.

This command will:
1. Clean any previous builds
2. Create the distribution structure
3. Copy all necessary files
4. Generate the install.sh script
5. Create the compressed tar.gz file
6. Place a README.md next to the compressed file in the dist/ directory

Run the build script:
```bash
bash /mnt/c/code/agentic-persona/build-distribution.sh
```

After completion, the distribution will be available at:
- Compressed package: `dist/ap-method-v1.0.0.tar.gz`
- Installation guide: `dist/README.md`