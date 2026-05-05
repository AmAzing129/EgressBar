import Foundation

struct IPInfo: Equatable {
    var ip: String?
    var city: String?
    var region: String?
    var country: String?
    var asn: String?
    var isp: String?

    static let empty = IPInfo()
}

struct IPInfoResponse: Decodable {
    var ip: String?
    var city: String?
    var region: String?
    var country: String?
    var org: String?
    var geo: Geo?
    var asn: ASN?
    var company: Company?

    enum CodingKeys: String, CodingKey {
        case ip
        case city
        case region
        case country
        case org
        case geo
        case asn
        case company
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ip = container.decodeFlexibleStringIfPresent(forKey: .ip)
        city = container.decodeFlexibleStringIfPresent(forKey: .city)
        region = container.decodeFlexibleStringIfPresent(forKey: .region)
        country = container.decodeFlexibleStringIfPresent(forKey: .country)
        org = container.decodeFlexibleStringIfPresent(forKey: .org)
        geo = try? container.decode(Geo.self, forKey: .geo)
        asn = try? container.decode(ASN.self, forKey: .asn)
        company = try? container.decode(Company.self, forKey: .company)
    }

    var normalized: IPInfo {
        IPInfo(
            ip: clean(ip),
            city: clean(geo?.city) ?? clean(city),
            region: clean(geo?.region) ?? clean(region),
            country: clean(geo?.country) ?? clean(country),
            asn: clean(asn?.asn) ?? clean(extractASN(from: org)),
            isp: clean(company?.name) ?? clean(asn?.name) ?? clean(org)
        )
    }

    private func extractASN(from org: String?) -> String? {
        guard let org else {
            return nil
        }

        let firstToken = org.split(separator: " ").first.map(String.init)
        guard let firstToken, firstToken.uppercased().hasPrefix("AS") else {
            return nil
        }

        return firstToken
    }
}

struct Geo: Decodable {
    var city: String?
    var region: String?
    var country: String?

    enum CodingKeys: String, CodingKey {
        case city
        case region
        case country
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        city = container.decodeFlexibleStringIfPresent(forKey: .city)
        region = container.decodeFlexibleStringIfPresent(forKey: .region)
        country = container.decodeFlexibleStringIfPresent(forKey: .country)
    }
}

struct ASN: Decodable {
    var asn: String?
    var name: String?

    enum CodingKeys: String, CodingKey {
        case asn
        case name
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        asn = container.decodeFlexibleStringIfPresent(forKey: .asn)
        name = container.decodeFlexibleStringIfPresent(forKey: .name)
    }
}

struct Company: Decodable {
    var name: String?

    enum CodingKeys: String, CodingKey {
        case name
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = container.decodeFlexibleStringIfPresent(forKey: .name)
    }
}

private struct NamedValue: Decodable {
    var id: String?
    var code: String?
    var name: String?
    var title: String?

    enum CodingKeys: String, CodingKey {
        case id
        case code
        case name
        case title
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.decodeFlexibleStringIfPresent(forKey: .id)
        code = container.decodeFlexibleStringIfPresent(forKey: .code)
        name = container.decodeFlexibleStringIfPresent(forKey: .name)
        title = container.decodeFlexibleStringIfPresent(forKey: .title)
    }
}

extension KeyedDecodingContainer {
    func decodeFlexibleStringIfPresent(forKey key: Key) -> String? {
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            return clean(value)
        }

        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return String(value)
        }

        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return String(value)
        }

        if let value = try? decodeIfPresent(NamedValue.self, forKey: key) {
            return clean(value.name) ?? clean(value.title) ?? clean(value.code) ?? clean(value.id)
        }

        return nil
    }
}

func clean(_ value: String?) -> String? {
    guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
          !trimmed.isEmpty else {
        return nil
    }

    return trimmed
}
