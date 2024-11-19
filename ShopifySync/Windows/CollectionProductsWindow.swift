import SwiftUI

class CollectionProductsWindow: NSWindow {
    convenience init(collection: Collection, viewModel: ShopifyViewModel) {
        self.init(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        title = "Products in \(collection.title)"
        contentView = NSHostingView(rootView: CollectionProductsView(viewModel: viewModel, collection: collection))
        center()
        
        // Set minimum window size
        setContentSize(NSSize(width: 800, height: 600))
        minSize = NSSize(width: 800, height: 600)
        
        // Prevent window from closing the app
        isReleasedWhenClosed = false
    }
} 