import UIKit
import WebKit

extension BrowserViewController {

    func openURL(_ url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
        updateURLBar()
    }
}

extension UIColor {

    static func dynamicColor(
        light: UIColor,
        dark: UIColor
    ) -> UIColor {
        return UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        }
    }
}

extension UIView {

    func addRoundedCorner(_ radius: CGFloat) {
        layer.cornerRadius = radius
        layer.masksToBounds = true
    }
}

extension String {

    var isValidURL: Bool {
        guard let url = URL(string: self) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    func truncated(toLength length: Int, trailing: String = "...") -> String {
        if count > length {
            return String(prefix(length)) + trailing
        }
        return self
    }
}

extension Date {

    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: self,
            to: now
        )

        if let years = components.year, years > 0 { return "\(years)年前" }
        if let months = components.month, months > 0 { return "\(months)个月前" }
        if let days = components.day, days > 0 { return "\(days)天前" }
        if let hours = components.hour, hours > 0 { return "\(hours)小时前" }
        if let minutes = components.minute, minutes > 0 { return "\(minutes)分钟前" }
        if let seconds = components.second, seconds > 0 { return "\(seconds)秒前" }
        return "刚刚"
    }
}
