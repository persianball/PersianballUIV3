class URLs{
    // static const baseUrl = "https://api2.persianball.ir";
    static const baseUrl = "https://pball.ah8ad3.ir/";

    /// اسکیم اختصاصی اپ: persianball://product/12
    static const appScheme = "persianball";

    /// baseUrl بدونِ اسلشِ انتهایی — برای ساختنِ لینک‌های قابلِ اشتراک
    /// (با baseUrl خام لینک «//product/9» می‌شد).
    static String get origin =>
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

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
