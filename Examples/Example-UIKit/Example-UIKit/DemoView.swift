import SwiftUI

struct DemoView: View {
    
    @State private var isShipActive: Bool = false
    @State private var isHomeActive: Bool = false
    @State private var isAboutActive: Bool = false
    
    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                NavigationStack {
                    VStack {
                        NavigationLink(destination: ShipView() , isActive: $isShipActive) {
                            Button("Go to Ship") {
                                isShipActive = true
                            }
                        }
                        
                        NavigationLink(destination: HomeView(viewModel: ItemViewModel()) , isActive: $isHomeActive) {
                            Button("Go to Home") {
                                isHomeActive = true
                            }
                        }
                        
                        NavigationLink(destination: AboutView() , isActive: $isAboutActive) {
                            Button("Go to About") {
                                isAboutActive = true
                            }
                        }
                    }
                }
            } else {
                NavigationView {
                    EmptyView()
                }
            }
        }
    }
}

struct LineItemRow<ModifiedTitle: View>: View {
    let title: String
    let value: Double
    let currencyCode: String
    let titleModifier: (Text) -> ModifiedTitle

    init(
        title: String,
        value: Double,
        currencyCode: String = "$",
        @ViewBuilder titleModifier: @escaping (Text) -> ModifiedTitle = { $0 }
    ) {
        self.title = title
        self.currencyCode = currencyCode
        self.value = value
        self.titleModifier = titleModifier
    }

    public var body: some View {
        HStack {
            titleModifier(Text(title))

            Spacer()

            Text(
                value,
                format: .currency(
                    code: currencyCode))
        }
    }
}

final class ItemViewModel: ObservableObject {
    
    var estimatedTax: Double {
        50
    }
    
    var itemCount: Int {
        4
    }
    
    var itemTotal: Double {
        400
    }
    
    var shipping: Double {
        0.0
    }
    
    var total: Double {
        estimatedTax + shipping + itemTotal
    }
}
