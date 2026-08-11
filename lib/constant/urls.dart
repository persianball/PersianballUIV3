class URLs{
    // static const baseUrl = "https://api2.persianball.ir";
    static const baseUrl = "http://2.144.27.195:8000";

    /// اسکیم اختصاصی اپ: marketky://product/12
    static const appScheme = "marketky";

    /// هاست‌هایی که لینک وبشان باید داخل اپ باز شود.
    /// وقتی دامنه نهایی آماده شد فقط کافی است اینجا و در AndroidManifest
    /// (و برای iOS در Associated Domains) اضافه شود.
    static const List<String> deepLinkHosts = [
      "2.144.27.195",
      "api2.persianball.ir",
    ];

    static bool isDeepLinkHost(String host) =>
        deepLinkHosts.contains(host.toLowerCase());
}
