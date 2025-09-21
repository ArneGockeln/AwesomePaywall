# AwesomePaywall
A SwiftUI Paywall and StoreManager for macOS and iOS apps.

## 💻 Installation

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for managing the distribution of Swift code. It’s integrated with the Swift build system to automate the process of downloading, compiling, and linking dependencies.

To integrate `AwesomePaywall` into your Xcode project using Xcode 26, specify it in `File > Swift Packages > Add Package Dependency...`:

```ogdl
https://https://github.com/ArneGockeln/AwesomePaywall.git, :branch="main"
```

## 🌄 Usage
### 1. Setup AppStore Connect
- Sign in to [AppStore Connect](https://appstoreconnect.apple.com){:target="_blank"}
- Go to `Apps` > `Your App Name` > `Subscriptions` > Subscription Group
- Create a unique group: for example "ElatedSubscriptions"

#### Annual Plan
- Go to that new group
- Create a new subscription with Reference Name "Annual Plan" and Product ID "YourAppNamePro.Annual"
- Set Subscription Duration to 1 year
- Set a price for the annual plan. Like 29.99

#### Weekly Plan
- Create a new subscription with Reference Name "Weekly Plan" and Product ID "YourAppNamePro.Weekly"
- Set Subscription Duration to 1 week
- Set a price for the weekly plan. Like 4.99

#### Free for 3 days
- Set an [introductory offer](https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-introductory-offers-for-auto-renewable-subscriptions/){:target="_blank"} for the weekly plan of 3 days
- Go to the weekly plan
- Click on (+) next to Subscription Prices and choose Introductory Offer
- Set start date and no end date!
- Select free and duration 3 days

### 2. Add storekit File
In Xcode add a synchronised storekit file to your project.

- Go to `File` > `New` > `File from Template`
- Search for storekit
- Tick the box "Synchronise"
- Choose your team and app bundle id
- Add the storekit file to your project target 

### 3. Setup the StoreManager
To setup the StoreManager just import AwesomePaywall in your main app file and run a configuration task.
Don't forget to set the product identifiers, terms of use and privacy policy web urls!

```swift
import SwiftUI
// Import the Package
import AwesomePaywall

@main
struct ElatedApp: App {
    // Initialise the StoreManager
    @StateObject private var storeManager: StoreManager = .shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Add task to fetch the configuration and synchronise purchases
                .task {
                    // set an ordered list of product identifiers. First in list appears first in paywall.
                    let identifiers = [
                        "YourAppNamePro.Annual",
                        "YourAppNamePro.Weekly"
                    ]
                    
                    await storeManager.configure(productIdentifiers: identifiers,
                         termsOfUseUrl: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/",
                         privacyUrl: "https://yourdomain.com/privacy"
                    ))
                }
        }
        // Make the StoreManager accessible to underlying views
        .environmentObject(self.storeManager)
    }
}
```

### 4. Add paywall to view
The paywall needs to get triggered by a state var. For example if a feature is only available to subscribers, toggle the state var and present the paywall.

```swift
import SwiftUI
import AwesomePaywall

struct ContentView: View {
    @State private var isPaywallPresented: Bool = false
    @EnvironmentObject private var storeManager: StoreManager

    var body: some View {
        VStack {
            // Toggle the paywall
            Button(action: { isPaywallPresented.toggle() }) {
                Text("Subscribe")
            }

            // Check if the current user is a paying customer
            if storeManager.isPayingCustomer() {
                Text("This is only for subscribers visible")
            }
        }
        // Add Paywall fullscreen cover
        .awesomePaywall(isPresented: $isPaywallPresented) {
            // This represents the Title and main Features
            PaywallHeroView()
        }
    }
}
```

### 5. Style the Hero View
The hero view contains the title and main features above the product selector. It can be styled as you like. An example is available in `Example` folder.

Also the paywall has 2 color options. The backgroundColor and highlightColor.

```swift
.awesomePaywall(isPresented: $isPaywallPresented, backgroundColor: Color.white, highlightColor: Color.green) {
    PaywallHeroView()
}
```

The backgroundColor is fullscreen and the highlightColor tints the border of the selected product and the background of the trial switch. 

## Requirements
- iOS v17 is the minimum requirement.
- Swift 5+
- A SwiftUI Project

## 📃 License
`AwesomePaywall` is available under the MIT license. See the [LICENSE](https://github.com/ArneGockeln/AwesomePaywall/blob/main/LICENSE) file for more info.

## 📦 Projects

The following projects have integrated AwesomePaywall in their App.

- [Elated | Widget Counter](https://arnesoftware.com/apps) available on the [AppStore](https://apps.apple.com/de/app/elated-urlaubs-countdown-timer/id6740820297)
