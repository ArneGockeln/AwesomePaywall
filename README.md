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

### 3. Setup the Paywall
To setup the paywall just import AwesomePaywall in your main app file and apply the view modifier to ContentView.
Don't forget to set the product identifiers, terms of use and privacy policy web urls!

```swift
import SwiftUI
import AwesomePaywall

@main
struct AppMain: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .awesomePaywall(with: APConfiguration(
                        productIDs: ["YourApp.Annual", "YourApp.Weekly"],
                        privacyUrl: URL(string: "https://yourdomain.com/privacy")!,
                        termsOfServiceUrl: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!,
                        backgroundColor: Color.red,
                        foregroundColor: Color.black
                    )
                ) {
                    PaywallMarketingView()
                }
        }
    }
}
```

### 4. Present a paywall
The paywall needs to get triggered by a state var. For example if a feature is only available to subscribers, toggle the state var and present the paywall.

```swift
import SwiftUI
import AwesomePaywall

struct ContentView: View {
    // Get access to the APStore
    @EnvironmentObject private var storeModel: APStore

    var body: some View {
        VStack {
            // Toggle the paywall
            Button(action: { storeModel.isPaywallPresented.toggle() }) {
                Text("Subscribe")
            }

            // Check if the current user is a paying customer
            if storeModel.hasProSubscription {
                Text("This is only for subscribers visible")
            }
        }
    }
}
```

### 5. Style the Marketing View
The marketing view contains a title and main features above the product selector. It can be styled as you like. An example is available in `Example` folder.

Also the paywall has 2 color options. The backgroundColor is fullscreen and the foregroundColor tints the border of the selected product and the background of the trial switch. 

```swift
.awesomePaywall(...) {
    PaywallMarketingView()
}
``` 

## Requirements
- iOS v18 is the minimum requirement.
- Swift 5+
- A SwiftUI Project

## 📃 License
`AwesomePaywall` is available under the MIT license. See the [LICENSE](https://github.com/ArneGockeln/AwesomePaywall/blob/main/LICENSE) file for more info.

## 📦 Projects

The following projects have integrated AwesomePaywall in their App.

- [Elated | Widget Counter](https://arnesoftware.com/apps) available on the [AppStore](https://apps.apple.com/de/app/elated-urlaubs-countdown-timer/id6740820297)
