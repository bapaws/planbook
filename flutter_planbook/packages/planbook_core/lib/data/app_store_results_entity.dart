class AppStoreResultListEntity {
  AppStoreResultListEntity({this.resultCount, this.results});

  AppStoreResultListEntity.fromJson(Map<String, dynamic> json) {
    resultCount = json['resultCount'] as int?;
    if (json['results'] != null) {
      results = <AppStoreResultEntity>[];
      for (final v in json['results'] as List<dynamic>) {
        results!.add(AppStoreResultEntity.fromJson(v as Map<String, dynamic>));
      }
    }
  }

  int? resultCount;
  List<AppStoreResultEntity>? results;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['resultCount'] = resultCount;
    if (results != null) {
      data['results'] = results!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class AppStoreResultEntity {
  AppStoreResultEntity({
    this.isGameCenterEnabled,
    this.artistViewUrl,
    this.artworkUrl60,
    this.artworkUrl100,
    this.features,
    this.supportedDevices,
    this.advisories,
    this.kind,
    this.artworkUrl512,
    this.screenshotUrls,
    this.ipadScreenshotUrls,
    this.appletvScreenshotUrls,
    this.trackCensoredName,
    this.trackViewUrl,
    this.contentAdvisoryRating,
    this.averageUserRating,
    this.artistId,
    this.artistName,
    this.genres,
    this.price,
    this.bundleId,
    this.currentVersionReleaseDate,
    this.trackId,
    this.trackName,
    this.releaseDate,
    this.primaryGenreName,
    this.primaryGenreId,
    this.releaseNotes,
    this.sellerName,
    this.genreIds,
    this.isVppDeviceBasedLicensingEnabled,
    this.version,
    this.wrapperType,
    this.currency,
    this.description,
    this.minimumOsVersion,
    this.languageCodesISO2A,
    this.fileSizeBytes,
    this.formattedPrice,
    this.userRatingCountForCurrentVersion,
    this.trackContentRating,
    this.averageUserRatingForCurrentVersion,
    this.userRatingCount,
  });

  AppStoreResultEntity.fromJson(Map<String, dynamic> json) {
    isGameCenterEnabled = json['isGameCenterEnabled'] as bool?;
    artistViewUrl = json['artistViewUrl'] as String?;
    artworkUrl60 = json['artworkUrl60'] as String?;
    artworkUrl100 = json['artworkUrl100'] as String?;
    features = json['features'] as List<String>?;
    supportedDevices = json['supportedDevices'] as List<String>?;
    advisories = json['advisories'] as List<String>?;
    kind = json['kind'] as String?;
    artworkUrl512 = json['artworkUrl512'] as String?;
    screenshotUrls = json['screenshotUrls'] as List<String>?;
    ipadScreenshotUrls = json['ipadScreenshotUrls'] as List<String>?;
    appletvScreenshotUrls = json['appletvScreenshotUrls'] as List<String>?;
    trackCensoredName = json['trackCensoredName'] as String?;
    trackViewUrl = json['trackViewUrl'] as String?;
    contentAdvisoryRating = json['contentAdvisoryRating'] as String?;
    averageUserRating = json['averageUserRating'] as num?;
    artistId = json['artistId'] as int?;
    artistName = json['artistName'] as String?;
    genres = json['genres'] as List<String>?;
    price = json['price'] as double?;
    bundleId = json['bundleId'] as String?;
    currentVersionReleaseDate = json['currentVersionReleaseDate'] as String?;
    trackId = json['trackId'] as int?;
    trackName = json['trackName'] as String?;
    releaseDate = json['releaseDate'] as String?;
    primaryGenreName = json['primaryGenreName'] as String?;
    primaryGenreId = json['primaryGenreId'] as int?;
    releaseNotes = json['releaseNotes'] as String?;
    sellerName = json['sellerName'] as String?;
    genreIds = json['genreIds'] as List<String>?;
    isVppDeviceBasedLicensingEnabled =
        json['isVppDeviceBasedLicensingEnabled'] as bool?;
    version = json['version'] as String?;
    wrapperType = json['wrapperType'] as String?;
    currency = json['currency'] as String?;
    description = json['description'] as String?;
    minimumOsVersion = json['minimumOsVersion'] as String?;
    languageCodesISO2A = json['languageCodesISO2A'] as List<String>?;
    fileSizeBytes = json['fileSizeBytes'] as String?;
    formattedPrice = json['formattedPrice'] as String?;
    userRatingCountForCurrentVersion =
        json['userRatingCountForCurrentVersion'] as int?;
    trackContentRating = json['trackContentRating'] as String?;
    averageUserRatingForCurrentVersion =
        json['averageUserRatingForCurrentVersion'] as num?;
    userRatingCount = json['userRatingCount'] as int?;
  }
  bool? isGameCenterEnabled;
  String? artistViewUrl;
  String? artworkUrl60;
  String? artworkUrl100;
  List<String>? features;
  List<String>? supportedDevices;
  List<String>? advisories;
  String? kind;
  String? artworkUrl512;
  List<String>? screenshotUrls;
  List<String>? ipadScreenshotUrls;
  List<String>? appletvScreenshotUrls;
  String? trackCensoredName;
  String? trackViewUrl;
  String? contentAdvisoryRating;
  num? averageUserRating;
  int? artistId;
  String? artistName;
  List<String>? genres;
  double? price;
  String? bundleId;
  String? currentVersionReleaseDate;
  int? trackId;
  String? trackName;
  String? releaseDate;
  String? primaryGenreName;
  int? primaryGenreId;
  String? releaseNotes;
  String? sellerName;
  List<String>? genreIds;
  bool? isVppDeviceBasedLicensingEnabled;
  String? version;
  String? wrapperType;
  String? currency;
  String? description;
  String? minimumOsVersion;
  List<String>? languageCodesISO2A;
  String? fileSizeBytes;
  String? formattedPrice;
  int? userRatingCountForCurrentVersion;
  String? trackContentRating;
  num? averageUserRatingForCurrentVersion;
  int? userRatingCount;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['isGameCenterEnabled'] = isGameCenterEnabled;
    data['artistViewUrl'] = artistViewUrl;
    data['artworkUrl60'] = artworkUrl60;
    data['artworkUrl100'] = artworkUrl100;
    data['features'] = features;
    data['supportedDevices'] = supportedDevices;
    data['advisories'] = advisories;
    data['kind'] = kind;
    data['artworkUrl512'] = artworkUrl512;
    data['screenshotUrls'] = screenshotUrls;
    data['ipadScreenshotUrls'] = ipadScreenshotUrls;
    data['appletvScreenshotUrls'] = appletvScreenshotUrls;
    data['trackCensoredName'] = trackCensoredName;
    data['trackViewUrl'] = trackViewUrl;
    data['contentAdvisoryRating'] = contentAdvisoryRating;
    data['averageUserRating'] = averageUserRating;
    data['artistId'] = artistId;
    data['artistName'] = artistName;
    data['genres'] = genres;
    data['price'] = price;
    data['bundleId'] = bundleId;
    data['currentVersionReleaseDate'] = currentVersionReleaseDate;
    data['trackId'] = trackId;
    data['trackName'] = trackName;
    data['releaseDate'] = releaseDate;
    data['primaryGenreName'] = primaryGenreName;
    data['primaryGenreId'] = primaryGenreId;
    data['releaseNotes'] = releaseNotes;
    data['sellerName'] = sellerName;
    data['genreIds'] = genreIds;
    data['isVppDeviceBasedLicensingEnabled'] = isVppDeviceBasedLicensingEnabled;
    data['version'] = version;
    data['wrapperType'] = wrapperType;
    data['currency'] = currency;
    data['description'] = description;
    data['minimumOsVersion'] = minimumOsVersion;
    data['languageCodesISO2A'] = languageCodesISO2A;
    data['fileSizeBytes'] = fileSizeBytes;
    data['formattedPrice'] = formattedPrice;
    data['userRatingCountForCurrentVersion'] = userRatingCountForCurrentVersion;
    data['trackContentRating'] = trackContentRating;
    data['averageUserRatingForCurrentVersion'] =
        averageUserRatingForCurrentVersion;
    data['userRatingCount'] = userRatingCount;
    return data;
  }
}
