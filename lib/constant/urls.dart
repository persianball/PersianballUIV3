class URLs{
    // static const baseUrl = "https://api2.persianball.ir";
    static const baseUrl = "https://pball.ah8ad3.ir/";

    /// اسکیم اختصاصی اپ: persianball://product/12
    static const appScheme = "persianball";

    /// هاست‌هایی که لینک وبشان باید داخل اپ باز شود.
    /// وقتی دامنه نهایی آماده شد فقط کافی است اینجا و در AndroidManifest
    /// (و برای iOS در Associated Domains) اضافه شود.
    static const List<String> deepLinkHosts = [
      "2.144.27.195",
      "api2.persianball.ir",
      "pball.ah8ad3.ir"
    ];

    static bool isDeepLinkHost(String host) =>
        deepLinkHosts.contains(host.toLowerCase());
}
