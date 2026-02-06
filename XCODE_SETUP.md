# Xcode Project Setup Instructions

## Files to Add to Xcode Project

The following Swift files were created and need to be added to your Xcode project. Follow these steps:

### Step 1: Open Xcode Project
```bash
cd "/Users/jaychung/Virtual Nutritionist/Virtual Nutritionist iOS"
open "Virtual Nutritionist iOS.xcodeproj"
```

### Step 2: Add New Files

Right-click on the project navigator and select "Add Files to..." for each new file:

#### Services Folder (Right-click "Services" → Add Files)
1. ✅ `Services/KeychainService.swift` (NEW)
2. ✅ `Services/AuthService.swift` (NEW)
3. ⚠️ `Services/APIService.swift` (MODIFIED - already in project)

#### ViewModels Folder (Create folder if it doesn't exist)
1. Right-click project → New Group → Name it "ViewModels"
2. ✅ `ViewModels/AuthViewModel.swift` (NEW)

#### Models Folder (Right-click "Models" → Add Files)
1. ✅ `Models/User.swift` (NEW)
2. ✅ `Models/ScanHistory.swift` (NEW)
3. ✅ `Models/Bookmark.swift` (NEW)
4. ⚠️ `Models/UserProfile.swift` (MODIFIED - already in project)

#### Views/Auth Folder (Create new group)
1. Right-click "Views" → New Group → Name it "Auth"
2. ✅ `Views/Auth/LoginView.swift` (NEW)
3. ✅ `Views/Auth/SignupView.swift` (NEW)
4. ✅ `Views/Auth/AuthContainerView.swift` (NEW)

#### Views/History Folder (Create new group)
1. Right-click "Views" → New Group → Name it "History"
2. ✅ `Views/History/ScanHistoryView.swift` (NEW)
3. ✅ `Views/History/ScanDetailView.swift` (NEW)

#### Views/Bookmarks Folder (Create new group)
1. Right-click "Views" → New Group → Name it "Bookmarks"
2. ✅ `Views/Bookmarks/BookmarksView.swift` (NEW)

#### App & Views (Already exist, but modified)
- ⚠️ `App/MenuScannerApp.swift` (MODIFIED)
- ⚠️ `Views/ContentView.swift` (MODIFIED)
- ⚠️ `Views/ResultsView.swift` (MODIFIED)

### Step 3: Verify Target Membership

For each new file:
1. Select the file in Project Navigator
2. Open File Inspector (right panel)
3. Under "Target Membership", ensure your app target is checked
4. Should look like: `☑ Virtual Nutritionist iOS`

### Step 4: Verify Build Settings

No changes needed to build settings, but verify:
- **iOS Deployment Target**: iOS 16.0 or later (for async/await)
- **Swift Language Version**: Swift 5
- **Keychain Sharing**: Not required (using default app group)

### Step 5: Build the Project

1. Select target device: iPhone 15 Pro (simulator recommended for testing)
2. Press `Cmd+B` to build
3. Should compile without errors

If you see errors:
- ✅ Check all new files are added
- ✅ Verify target membership
- ✅ Clean build folder: `Cmd+Shift+K`
- ✅ Rebuild: `Cmd+B`

### Step 6: Run and Test

1. Press `Cmd+R` to run
2. App should launch and show login/signup screen
3. Follow testing steps in `QUICK_START.md`

## File Structure After Setup

```
Virtual Nutritionist iOS/
├── App/
│   └── MenuScannerApp.swift (modified)
├── Services/
│   ├── KeychainService.swift (new)
│   ├── AuthService.swift (new)
│   ├── APIService.swift (modified)
│   └── CameraService.swift (existing)
├── ViewModels/
│   └── AuthViewModel.swift (new)
├── Models/
│   ├── User.swift (new)
│   ├── ScanHistory.swift (new)
│   ├── Bookmark.swift (new)
│   ├── UserProfile.swift (modified)
│   ├── MenuItem.swift (existing)
│   └── DietaryProtocol.swift (existing)
├── Views/
│   ├── Auth/
│   │   ├── LoginView.swift (new)
│   │   ├── SignupView.swift (new)
│   │   └── AuthContainerView.swift (new)
│   ├── History/
│   │   ├── ScanHistoryView.swift (new)
│   │   └── ScanDetailView.swift (new)
│   ├── Bookmarks/
│   │   └── BookmarksView.swift (new)
│   ├── ContentView.swift (modified)
│   ├── ResultsView.swift (modified)
│   ├── CameraView.swift (existing)
│   └── ProfileView.swift (existing)
└── Info.plist
```

## Common Build Errors & Solutions

### Error: "Cannot find 'KeychainService' in scope"
**Solution**:
- Verify `KeychainService.swift` is added to project
- Check target membership
- Clean and rebuild

### Error: "Cannot find type 'AuthViewModel' in scope"
**Solution**:
- Verify `AuthViewModel.swift` is added to project
- Ensure it's in the same target as other files

### Error: "Value of type 'MenuScannerApp' has no member 'authViewModel'"
**Solution**:
- Check that `MenuScannerApp.swift` was properly modified
- Verify the `@StateObject private var authViewModel = AuthViewModel()` line exists

### Error: "Cannot find 'AuthContainerView' in scope"
**Solution**:
- Verify all Auth views are added: `LoginView.swift`, `SignupView.swift`, `AuthContainerView.swift`
- Check they're in the same target

### Error: "Missing return in closure expected to return 'some View'"
**Solution**:
- This usually means a syntax error in a SwiftUI view
- Check the file mentioned in error
- Verify all braces `{}` are properly closed

## Testing in Simulator

### Recommended Simulator
- **iPhone 15 Pro** (iOS 17+)
- Good screen size for testing TabView
- Fast performance

### Quick Test Flow
1. Build and run (Cmd+R)
2. Should see Sign In / Sign Up screen
3. Tap "Sign Up" tab
4. Enter:
   - Email: `test@example.com`
   - Password: `Test1234`
   - Confirm: `Test1234`
5. Tap "Sign Up"
6. Should enter app with 4 tabs visible

### Simulator Menu Items
- `Device → Erase All Content and Settings`: Reset Keychain
- `Hardware → Shake Gesture`: Useful for debugging
- `Features → Face ID → Enrolled`: If using biometric auth later

## Troubleshooting Keychain in Simulator

If you see Keychain errors:
1. Stop the app
2. `Device → Erase All Content and Settings`
3. Rebuild and run
4. Try again

Alternatively, test on a real device where Keychain is more reliable.

## Next Steps After Xcode Setup

1. ✅ Verify all files compile
2. ✅ Run on simulator
3. ✅ Test authentication flow
4. ✅ Test all 4 tabs
5. 📱 Test on real device
6. 🚀 Prepare for App Store submission

## Checklist Before Submitting PR/Commit

- [ ] All new files added to Xcode
- [ ] Project builds without errors
- [ ] App runs on simulator
- [ ] Can sign up new user
- [ ] Can login existing user
- [ ] Can scan menu
- [ ] Can view history
- [ ] Can bookmark items
- [ ] Can logout
- [ ] Backend URL is correct (production URL)
- [ ] No hardcoded test credentials in code

## Need Help?

If you encounter issues:
1. Check this file first
2. Clean build folder: `Cmd+Shift+K`
3. Restart Xcode
4. Reset simulator
5. Check `QUICK_START.md` for backend issues
6. Check `IMPLEMENTATION_SUMMARY.md` for architecture details
