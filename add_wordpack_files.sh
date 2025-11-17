#!/bin/bash

# Script to help add WordPack files to Xcode project
# This lists all the new files that need to be added

echo "====================================================="
echo "WordPack Files to Add to Xcode Project"
echo "====================================================="
echo ""
echo "Please add these files to your Xcode project:"
echo ""

NEW_FILES=(
    "Gamoitsani/Source/Common/Models/WordPack/WordPackFirebase.swift"
    "Gamoitsani/Source/Common/Models/WordPack/WordPackExtensions.swift"
    "Gamoitsani/Source/Common/Utils/Managers/FirebaseManager+WordPack.swift"
    "Gamoitsani/Source/Modules/WordPack/WordPackCoordinator.swift"
    "Gamoitsani/Source/Modules/WordPack/PackList/PackListViewModel.swift"
    "Gamoitsani/Source/Modules/WordPack/PackList/PackListView.swift"
    "Gamoitsani/Source/Modules/WordPack/PackList/PackDetailsView.swift"
    "Gamoitsani/Source/Modules/WordPack/PackCreator/PackCreatorViewModel.swift"
    "Gamoitsani/Source/Modules/WordPack/PackCreator/PackCreatorView.swift"
    "Gamoitsani/Source/Modules/WordPack/WordBrowser/WordBrowserViewModel.swift"
    "Gamoitsani/Source/Modules/WordPack/WordBrowser/WordBrowserView.swift"
)

for file in "${NEW_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file"
    else
        echo "  ✗ $file (NOT FOUND)"
    fi
done

echo ""
echo "====================================================="
echo "How to Add Files to Xcode:"
echo "====================================================="
echo "1. Open Gamoitsani.xcodeproj in Xcode"
echo "2. In the Project Navigator, select all these folders:"
echo "   - Common/Models/WordPack"
echo "   - Common/Utils/Managers (for FirebaseManager+WordPack.swift)"
echo "   - Modules/WordPack"
echo "3. Right-click and choose 'Add Files to Gamoitsani...'"
echo "4. Navigate to each folder and select the files"
echo "5. Make sure 'Copy items if needed' is UNCHECKED"
echo "6. Make sure 'Add to targets: Gamoitsani' is CHECKED"
echo "7. Click 'Add'"
echo ""
echo "OR use this faster method:"
echo "1. Open Finder and navigate to Gamoitsani/Source/"
echo "2. Drag the 'WordPack' folders into Xcode's Project Navigator"
echo "3. When prompted, make sure 'Create groups' is selected"
echo "4. Make sure target 'Gamoitsani' is checked"
echo ""
