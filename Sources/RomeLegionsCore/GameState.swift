public enum Faction: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case rome
    case carthage
    case gaul
    case egypt
    case neutral

    public var id: String { rawValue }

    public static var turnOrder: [Faction] {
        [.rome, .carthage, .gaul, .egypt]
    }

    public var displayName: String {
        switch self {
        case .rome: return "罗马"
        case .carthage: return "迦太基"
        case .gaul: return "高卢"
        case .egypt: return "埃及"
        case .neutral: return "中立"
        }
    }
}

public enum GameMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case campaign
    case conquest
    case expedition

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .campaign: return "战役"
        case .conquest: return "征服"
        case .expedition: return "远征"
        }
    }

    public var subtitle: String {
        switch self {
        case .campaign: return "布匿战争序章"
        case .conquest: return "地中海霸权"
        case .expedition: return "有限兵力突破"
        }
    }
}

public enum DiplomaticStatus: String, CaseIterable, Codable, Identifiable, Sendable {
    case war
    case truce
    case alliance

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .war: return "战争"
        case .truce: return "停战"
        case .alliance: return "同盟"
        }
    }
}

public struct DiplomaticRelation: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var first: Faction
    public var second: Faction
    public var status: DiplomaticStatus

    public init(first: Faction, second: Faction, status: DiplomaticStatus) {
        let ordered = DiplomaticRelation.ordered(first, second)
        self.id = DiplomaticRelation.id(for: ordered.0, ordered.1)
        self.first = ordered.0
        self.second = ordered.1
        self.status = status
    }

    public func contains(_ faction: Faction) -> Bool {
        first == faction || second == faction
    }

    public func otherFaction(from faction: Faction) -> Faction? {
        if first == faction { return second }
        if second == faction { return first }
        return nil
    }

    public static func id(for first: Faction, _ second: Faction) -> String {
        let ordered = ordered(first, second)
        return "\(ordered.0.rawValue)-\(ordered.1.rawValue)"
    }

    private static func ordered(_ first: Faction, _ second: Faction) -> (Faction, Faction) {
        first.rawValue < second.rawValue ? (first, second) : (second, first)
    }
}

public enum TerrainType: String, CaseIterable, Codable, Hashable, Sendable {
    case plains
    case forest
    case hills
    case water
    case road
    case city

    public var displayName: String {
        switch self {
        case .plains: return "平原"
        case .forest: return "森林"
        case .hills: return "丘陵"
        case .water: return "海域"
        case .road: return "道路"
        case .city: return "城市"
        }
    }

    public var movementCost: Int {
        switch self {
        case .plains, .road, .city: return 1
        case .forest, .hills: return 2
        case .water: return 1
        }
    }

    public var defenseBonus: Int {
        switch self {
        case .plains, .road, .water: return 0
        case .forest: return 4
        case .hills: return 7
        case .city: return 10
        }
    }
}

public struct Position: Hashable, Codable, Sendable, CustomStringConvertible {
    public var x: Int
    public var y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    public var description: String {
        "(\(x),\(y))"
    }

    public func isInside(width: Int, height: Int) -> Bool {
        x >= 0 && x < width && y >= 0 && y < height
    }

    public func neighbors(width: Int, height: Int) -> [Position] {
        let evenRow = y.isMultiple(of: 2)
        let deltas = evenRow
            ? [(1, 0), (-1, 0), (0, -1), (-1, -1), (0, 1), (-1, 1)]
            : [(1, 0), (-1, 0), (1, -1), (0, -1), (1, 1), (0, 1)]

        return deltas
            .map { Position(x: x + $0.0, y: y + $0.1) }
            .filter { $0.isInside(width: width, height: height) }
    }

    public func hexDistance(to other: Position) -> Int {
        let a = cubeCoordinates()
        let b = other.cubeCoordinates()
        return (abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z)) / 2
    }

    private func cubeCoordinates() -> (x: Int, y: Int, z: Int) {
        let q = x - (y - (y & 1)) / 2
        let r = y
        return (q, -q - r, r)
    }
}

public struct Tile: Identifiable, Codable, Hashable, Sendable {
    public var position: Position
    public var terrain: TerrainType

    public init(position: Position, terrain: TerrainType) {
        self.position = position
        self.terrain = terrain
    }

    public var id: Position { position }
}

public struct EmpireResources: Codable, Equatable, Sendable {
    public var gold: Int
    public var grain: Int
    public var iron: Int
    public var science: Int
    public var prestige: Int

    public init(gold: Int, grain: Int, iron: Int, science: Int, prestige: Int) {
        self.gold = gold
        self.grain = grain
        self.iron = iron
        self.science = science
        self.prestige = prestige
    }

    public static let zero = EmpireResources(gold: 0, grain: 0, iron: 0, science: 0, prestige: 0)

    public func canPay(_ cost: EmpireResources) -> Bool {
        gold >= cost.gold &&
            grain >= cost.grain &&
            iron >= cost.iron &&
            science >= cost.science &&
            prestige >= cost.prestige
    }

    public mutating func add(_ value: EmpireResources) {
        gold += value.gold
        grain += value.grain
        iron += value.iron
        science += value.science
        prestige += value.prestige
    }

    public mutating func spend(_ cost: EmpireResources) throws {
        guard canPay(cost) else {
            throw GameRuleError.insufficientResources
        }

        gold -= cost.gold
        grain -= cost.grain
        iron -= cost.iron
        science -= cost.science
        prestige -= cost.prestige
    }
}

public enum UnitKind: String, CaseIterable, Codable, Identifiable, Sendable {
    case legion
    case cavalry
    case archer
    case navy

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .legion: return "军团"
        case .cavalry: return "骑兵"
        case .archer: return "弓兵"
        case .navy: return "舰队"
        }
    }

    public var attack: Int {
        switch self {
        case .legion: return 32
        case .cavalry: return 37
        case .archer: return 25
        case .navy: return 30
        }
    }

    public var defense: Int {
        switch self {
        case .legion: return 14
        case .cavalry: return 11
        case .archer: return 8
        case .navy: return 10
        }
    }

    public var movement: Int {
        switch self {
        case .legion: return 3
        case .cavalry: return 4
        case .archer: return 2
        case .navy: return 4
        }
    }

    public var range: Int {
        switch self {
        case .archer, .navy: return 2
        case .legion, .cavalry: return 1
        }
    }

    public var maxHealth: Int {
        switch self {
        case .legion: return 100
        case .cavalry: return 88
        case .archer: return 72
        case .navy: return 90
        }
    }

    public var recruitmentCost: EmpireResources {
        switch self {
        case .legion:
            EmpireResources(gold: 80, grain: 35, iron: 30, science: 0, prestige: 0)
        case .cavalry:
            EmpireResources(gold: 105, grain: 55, iron: 45, science: 0, prestige: 0)
        case .archer:
            EmpireResources(gold: 65, grain: 30, iron: 15, science: 0, prestige: 0)
        case .navy:
            EmpireResources(gold: 120, grain: 20, iron: 65, science: 0, prestige: 0)
        }
    }

    public func canEnter(_ terrain: TerrainType) -> Bool {
        switch self {
        case .navy:
            return terrain == .water
        case .legion, .cavalry, .archer:
            return terrain != .water
        }
    }
}

public enum TacticalOrder: String, CaseIterable, Codable, Identifiable, Hashable, Sendable {
    case balanced
    case assault
    case defensive
    case forcedMarch

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .balanced: return "均衡"
        case .assault: return "突击"
        case .defensive: return "坚守"
        case .forcedMarch: return "行军"
        }
    }

    public var detail: String {
        switch self {
        case .balanced: return "标准战斗姿态"
        case .assault: return "攻击 +6，防御 -3"
        case .defensive: return "防御 +6，攻击 -2，机动 -1"
        case .forcedMarch: return "机动 +2，攻击 -4，防御 -2"
        }
    }

    public var attackBonus: Int {
        switch self {
        case .balanced: return 0
        case .assault: return 6
        case .defensive: return -2
        case .forcedMarch: return -4
        }
    }

    public var defenseBonus: Int {
        switch self {
        case .balanced: return 0
        case .assault: return -3
        case .defensive: return 6
        case .forcedMarch: return -2
        }
    }

    public var movementBonus: Int {
        switch self {
        case .balanced, .assault: return 0
        case .defensive: return -1
        case .forcedMarch: return 2
        }
    }

    public var requiresFreshUnit: Bool {
        switch self {
        case .balanced, .assault, .defensive:
            return false
        case .forcedMarch:
            return true
        }
    }
}

public enum GeneralTrait: String, CaseIterable, Codable, Identifiable, Hashable, Sendable {
    case eagleStandard
    case siegeEngineer
    case quartermaster
    case shieldWall

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .eagleStandard: return "鹰旗统帅"
        case .siegeEngineer: return "攻城专家"
        case .quartermaster: return "军需官"
        case .shieldWall: return "盾墙指挥"
        }
    }

    public var passiveDetail: String {
        switch self {
        case .eagleStandard: return "攻击 +5，主动鼓舞后自身经验 +1"
        case .siegeEngineer: return "攻城伤害 +10，主动削弱相邻敌城城防"
        case .quartermaster: return "机动 +1，主动为周围友军补给"
        case .shieldWall: return "防御 +6，主动稳住周围友军阵线"
        }
    }

    public var skillName: String {
        switch self {
        case .eagleStandard: return "鹰旗鼓舞"
        case .siegeEngineer: return "攻城布阵"
        case .quartermaster: return "战地补给"
        case .shieldWall: return "盾墙号令"
        }
    }

    public var skillDetail: String {
        switch self {
        case .eagleStandard: return "恢复周围友军 12 生命，并让将领获得经验。"
        case .siegeEngineer: return "相邻敌方城市城防 -4。"
        case .quartermaster: return "恢复两格内友军 22 生命。"
        case .shieldWall: return "恢复相邻友军 14 生命。"
        }
    }

    public var attackBonus: Int {
        switch self {
        case .eagleStandard: return 5
        case .siegeEngineer, .quartermaster, .shieldWall: return 0
        }
    }

    public var siegeAttackBonus: Int {
        switch self {
        case .siegeEngineer: return 10
        case .eagleStandard, .quartermaster, .shieldWall: return 0
        }
    }

    public var defenseBonus: Int {
        switch self {
        case .shieldWall: return 6
        case .eagleStandard, .siegeEngineer, .quartermaster: return 0
        }
    }

    public var movementBonus: Int {
        switch self {
        case .quartermaster: return 1
        case .eagleStandard, .siegeEngineer, .shieldWall: return 0
        }
    }

    public var commandRange: Int {
        switch self {
        case .quartermaster: return 2
        case .eagleStandard, .siegeEngineer, .shieldWall: return 1
        }
    }

    public var recoveryAmount: Int {
        switch self {
        case .eagleStandard: return 12
        case .siegeEngineer: return 0
        case .quartermaster: return 22
        case .shieldWall: return 14
        }
    }

    public var fortificationReductionAmount: Int {
        switch self {
        case .siegeEngineer: return 4
        case .eagleStandard, .quartermaster, .shieldWall: return 0
        }
    }

    public var skillCooldownTurns: Int {
        2
    }

    public static func defaultTrait(forName name: String?) -> GeneralTrait? {
        guard let name else { return nil }

        switch name {
        case "凯撒", "庞培", "西庇阿":
            return .eagleStandard
        case "汉尼拔", "苏拉":
            return .siegeEngineer
        case "拉比埃努斯", "阿格里帕":
            return .quartermaster
        case "维钦托利", "布鲁图", "马略":
            return .shieldWall
        default:
            return .eagleStandard
        }
    }
}

public struct GeneralSkillPreview: Codable, Equatable, Sendable {
    public var unitID: String
    public var trait: GeneralTrait
    public var origin: Position
    public var range: Int
    public var rangePositions: [Position]
    public var affectedUnitIDs: [String]
    public var affectedCityIDs: [String]
    public var affectedPositions: [Position]
    public var projectedRecoveredHealth: Int
    public var projectedFortificationReduction: Int
    public var cooldownRemaining: Int
    public var cooldownText: String
    public var isExecutable: Bool
    public var blockedReason: String?
    public var summary: String
    public var detail: String

    public init(
        unitID: String,
        trait: GeneralTrait,
        origin: Position,
        range: Int,
        rangePositions: [Position],
        affectedUnitIDs: [String],
        affectedCityIDs: [String],
        affectedPositions: [Position],
        projectedRecoveredHealth: Int,
        projectedFortificationReduction: Int,
        cooldownRemaining: Int,
        cooldownText: String,
        isExecutable: Bool,
        blockedReason: String?,
        summary: String,
        detail: String
    ) {
        self.unitID = unitID
        self.trait = trait
        self.origin = origin
        self.range = range
        self.rangePositions = rangePositions
        self.affectedUnitIDs = affectedUnitIDs
        self.affectedCityIDs = affectedCityIDs
        self.affectedPositions = affectedPositions
        self.projectedRecoveredHealth = projectedRecoveredHealth
        self.projectedFortificationReduction = projectedFortificationReduction
        self.cooldownRemaining = cooldownRemaining
        self.cooldownText = cooldownText
        self.isExecutable = isExecutable
        self.blockedReason = blockedReason
        self.summary = summary
        self.detail = detail
    }
}

public struct WarMeritStatus: Codable, Equatable, Sendable {
    public var experience: Int
    public var rankName: String
    public var damageBonus: Int
    public var nextRankName: String?
    public var nextRankExperience: Int?
    public var currentRankExperience: Int
    public var progress: Int
    public var progressTarget: Int
    public var progressFraction: Double
    public var summary: String

    public init(experience: Int) {
        let normalizedExperience = max(0, experience)
        let ranks: [(experience: Int, name: String)] = [
            (0, "新兵"),
            (2, "老兵"),
            (4, "百夫长"),
            (7, "副将"),
            (10, "名将")
        ]

        let currentIndex = ranks.lastIndex { normalizedExperience >= $0.experience } ?? 0
        let currentRank = ranks[currentIndex]
        let nextRank = currentIndex + 1 < ranks.count ? ranks[currentIndex + 1] : nil
        let progressTarget = max(1, (nextRank?.experience ?? currentRank.experience + 1) - currentRank.experience)
        let progress = nextRank == nil ? progressTarget : min(progressTarget, normalizedExperience - currentRank.experience)

        self.experience = normalizedExperience
        self.rankName = currentRank.name
        self.damageBonus = normalizedExperience * 3
        self.nextRankName = nextRank?.name
        self.nextRankExperience = nextRank?.experience
        self.currentRankExperience = currentRank.experience
        self.progress = progress
        self.progressTarget = progressTarget
        self.progressFraction = Double(progress) / Double(progressTarget)

        if let nextRank {
            self.summary = "\(currentRank.name) · 战功 \(normalizedExperience)/\(nextRank.experience) · 伤害 +\(normalizedExperience * 3)"
        } else {
            self.summary = "\(currentRank.name) · 战功 \(normalizedExperience) · 伤害 +\(normalizedExperience * 3)"
        }
    }
}

public struct ArmyUnit: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var kind: UnitKind
    public var faction: Faction
    public var position: Position
    public var health: Int
    public var experience: Int
    public var generalName: String?
    public var generalTrait: GeneralTrait?
    public var generalSkillCooldownRemaining: Int
    public var tacticalOrder: TacticalOrder?
    public var hasMoved: Bool
    public var hasActed: Bool

    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case faction
        case position
        case health
        case experience
        case generalName
        case generalTrait
        case generalSkillCooldownRemaining
        case tacticalOrder
        case hasMoved
        case hasActed
    }

    public init(
        id: String,
        kind: UnitKind,
        faction: Faction,
        position: Position,
        health: Int? = nil,
        experience: Int = 0,
        generalName: String? = nil,
        generalTrait: GeneralTrait? = nil,
        generalSkillCooldownRemaining: Int = 0,
        tacticalOrder: TacticalOrder? = nil,
        hasMoved: Bool = false,
        hasActed: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.faction = faction
        self.position = position
        self.health = health ?? kind.maxHealth
        self.experience = experience
        self.generalName = generalName
        self.generalTrait = generalTrait
        self.generalSkillCooldownRemaining = max(0, generalSkillCooldownRemaining)
        self.tacticalOrder = tacticalOrder
        self.hasMoved = hasMoved
        self.hasActed = hasActed
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        kind = try container.decode(UnitKind.self, forKey: .kind)
        faction = try container.decode(Faction.self, forKey: .faction)
        position = try container.decode(Position.self, forKey: .position)
        health = try container.decode(Int.self, forKey: .health)
        experience = try container.decode(Int.self, forKey: .experience)
        generalName = try container.decodeIfPresent(String.self, forKey: .generalName)
        generalTrait = try container.decodeIfPresent(GeneralTrait.self, forKey: .generalTrait)
        generalSkillCooldownRemaining = max(0, try container.decodeIfPresent(Int.self, forKey: .generalSkillCooldownRemaining) ?? 0)
        tacticalOrder = try container.decodeIfPresent(TacticalOrder.self, forKey: .tacticalOrder)
        hasMoved = try container.decode(Bool.self, forKey: .hasMoved)
        hasActed = try container.decode(Bool.self, forKey: .hasActed)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(kind, forKey: .kind)
        try container.encode(faction, forKey: .faction)
        try container.encode(position, forKey: .position)
        try container.encode(health, forKey: .health)
        try container.encode(experience, forKey: .experience)
        try container.encodeIfPresent(generalName, forKey: .generalName)
        try container.encodeIfPresent(generalTrait, forKey: .generalTrait)
        try container.encode(generalSkillCooldownRemaining, forKey: .generalSkillCooldownRemaining)
        try container.encodeIfPresent(tacticalOrder, forKey: .tacticalOrder)
        try container.encode(hasMoved, forKey: .hasMoved)
        try container.encode(hasActed, forKey: .hasActed)
    }

    public var healthRatio: Double {
        Double(health) / Double(kind.maxHealth)
    }

    public var resolvedGeneralTrait: GeneralTrait? {
        generalTrait ?? GeneralTrait.defaultTrait(forName: generalName)
    }

    public var resolvedTacticalOrder: TacticalOrder {
        tacticalOrder ?? .balanced
    }

    public var hasGeneralSkillOnCooldown: Bool {
        generalSkillCooldownRemaining > 0
    }
}

public struct City: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var position: Position
    public var owner: Faction
    public var production: EmpireResources
    public var fortification: Int

    public init(
        id: String,
        name: String,
        position: Position,
        owner: Faction,
        production: EmpireResources,
        fortification: Int
    ) {
        self.id = id
        self.name = name
        self.position = position
        self.owner = owner
        self.production = production
        self.fortification = fortification
    }
}

public struct CityDevelopmentPreview: Equatable, Sendable {
    public var cityID: String
    public var cityName: String
    public var owner: Faction
    public var cost: EmpireResources
    public var productionIncrease: EmpireResources
    public var projectedProduction: EmpireResources
    public var fortificationIncrease: Int
    public var projectedFortification: Int
    public var canDevelop: Bool
    public var blockedReason: String?
    public var blockingError: GameRuleError?

    public init(
        cityID: String,
        cityName: String,
        owner: Faction,
        cost: EmpireResources,
        productionIncrease: EmpireResources,
        projectedProduction: EmpireResources,
        fortificationIncrease: Int,
        projectedFortification: Int,
        canDevelop: Bool,
        blockedReason: String?,
        blockingError: GameRuleError?
    ) {
        self.cityID = cityID
        self.cityName = cityName
        self.owner = owner
        self.cost = cost
        self.productionIncrease = productionIncrease
        self.projectedProduction = projectedProduction
        self.fortificationIncrease = fortificationIncrease
        self.projectedFortification = projectedFortification
        self.canDevelop = canDevelop
        self.blockedReason = blockedReason
        self.blockingError = blockingError
    }
}

public struct CityRecruitmentPreview: Equatable, Sendable {
    public var cityID: String
    public var cityName: String
    public var owner: Faction
    public var kind: UnitKind
    public var cost: EmpireResources
    public var deploymentPosition: Position?
    public var canRecruit: Bool
    public var blockedReason: String?
    public var blockingError: GameRuleError?

    public init(
        cityID: String,
        cityName: String,
        owner: Faction,
        kind: UnitKind,
        cost: EmpireResources,
        deploymentPosition: Position?,
        canRecruit: Bool,
        blockedReason: String?,
        blockingError: GameRuleError?
    ) {
        self.cityID = cityID
        self.cityName = cityName
        self.owner = owner
        self.kind = kind
        self.cost = cost
        self.deploymentPosition = deploymentPosition
        self.canRecruit = canRecruit
        self.blockedReason = blockedReason
        self.blockingError = blockingError
    }
}

public enum Technology: String, CaseIterable, Codable, Identifiable, Hashable, Sendable {
    case marchingDrill
    case siegeEngineering
    case navalCommand

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .marchingDrill: return "军团操练"
        case .siegeEngineering: return "攻城工程"
        case .navalCommand: return "海军指挥"
        }
    }

    public var detail: String {
        switch self {
        case .marchingDrill: return "陆军攻击 +4"
        case .siegeEngineering: return "攻击城市时伤害 +8"
        case .navalCommand: return "舰队攻击 +6"
        }
    }

    public var cost: EmpireResources {
        switch self {
        case .marchingDrill:
            EmpireResources(gold: 0, grain: 0, iron: 0, science: 45, prestige: 0)
        case .siegeEngineering:
            EmpireResources(gold: 20, grain: 0, iron: 20, science: 60, prestige: 0)
        case .navalCommand:
            EmpireResources(gold: 10, grain: 0, iron: 30, science: 55, prestige: 0)
        }
    }
}

public struct Mission: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var objective: String
    public var requirement: MissionRequirement?
    public var reward: EmpireResources
    public var isCompleted: Bool

    public init(
        id: String,
        title: String,
        objective: String,
        requirement: MissionRequirement? = nil,
        reward: EmpireResources,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.objective = objective
        self.requirement = requirement
        self.reward = reward
        self.isCompleted = isCompleted
    }
}

public enum MissionRequirement: Codable, Equatable, Sendable {
    case controlCity(cityID: String, faction: Faction)
    case factionUnitCount(faction: Faction, atLeast: Int)
}

public enum CampaignStatusKind: String, Codable, Equatable, Sendable {
    case ongoing
    case romanVictory
    case romanDefeat

    public var displayName: String {
        switch self {
        case .ongoing: return "战役进行中"
        case .romanVictory: return "罗马胜利"
        case .romanDefeat: return "罗马失败"
        }
    }
}

public struct CampaignStatus: Codable, Equatable, Sendable {
    public var kind: CampaignStatusKind
    public var title: String
    public var detail: String
    public var isGameOver: Bool
    public var primaryMissionID: String?
    public var progressText: String?

    public init(
        kind: CampaignStatusKind,
        title: String,
        detail: String,
        primaryMissionID: String? = nil,
        progressText: String? = nil
    ) {
        self.kind = kind
        self.title = title
        self.detail = detail
        self.isGameOver = kind != .ongoing
        self.primaryMissionID = primaryMissionID
        self.progressText = progressText
    }
}

public struct CombatPreview: Equatable, Sendable {
    public var attackerID: String
    public var defenderID: String
    public var damage: Int
    public var retaliation: Int
    public var supportBonus: Int
    public var flankingBonus: Int
    public var commandBonus: Int
    public var defenderSupportBonus: Int
    public var defenderRemainingHealth: Int
    public var attackerRemainingHealth: Int
    public var defeatsDefender: Bool
    public var attackerFalls: Bool

    public init(
        attackerID: String,
        defenderID: String,
        damage: Int,
        retaliation: Int,
        supportBonus: Int = 0,
        flankingBonus: Int = 0,
        commandBonus: Int = 0,
        defenderSupportBonus: Int = 0,
        defenderRemainingHealth: Int,
        attackerRemainingHealth: Int,
        defeatsDefender: Bool,
        attackerFalls: Bool
    ) {
        self.attackerID = attackerID
        self.defenderID = defenderID
        self.damage = damage
        self.retaliation = retaliation
        self.supportBonus = supportBonus
        self.flankingBonus = flankingBonus
        self.commandBonus = commandBonus
        self.defenderSupportBonus = defenderSupportBonus
        self.defenderRemainingHealth = defenderRemainingHealth
        self.attackerRemainingHealth = attackerRemainingHealth
        self.defeatsDefender = defeatsDefender
        self.attackerFalls = attackerFalls
    }

    public var totalAttackModifier: Int {
        supportBonus + flankingBonus + commandBonus
    }
}

public enum AIIntentKind: String, CaseIterable, Codable, Identifiable, Sendable {
    case attack
    case advanceAttack
    case captureCity
    case advance
    case defend
    case regroup
    case useSkill

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .attack: return "准备攻击"
        case .advanceAttack: return "接敌攻击"
        case .captureCity: return "夺取城市"
        case .advance: return "推进"
        case .defend: return "固守"
        case .regroup: return "整备"
        case .useSkill: return "发动技能"
        }
    }
}

public struct AIIntent: Identifiable, Codable, Equatable, Sendable {
    public var unitID: String
    public var faction: Faction
    public var kind: AIIntentKind
    public var tacticalOrder: TacticalOrder
    public var targetUnitID: String?
    public var targetCityID: String?
    public var destination: Position?
    public var projectedDamage: Int?
    public var threatScore: Int

    public init(
        unitID: String,
        faction: Faction,
        kind: AIIntentKind,
        tacticalOrder: TacticalOrder,
        targetUnitID: String? = nil,
        targetCityID: String? = nil,
        destination: Position? = nil,
        projectedDamage: Int? = nil,
        threatScore: Int
    ) {
        self.unitID = unitID
        self.faction = faction
        self.kind = kind
        self.tacticalOrder = tacticalOrder
        self.targetUnitID = targetUnitID
        self.targetCityID = targetCityID
        self.destination = destination
        self.projectedDamage = projectedDamage
        self.threatScore = threatScore
    }

    public var id: String { unitID }
}

public enum LegionFormationRole: String, CaseIterable, Identifiable, Equatable, Sendable {
    case vanguard
    case line
    case command
    case support
    case siege
    case reserve
    case fleet

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .vanguard: return "先锋"
        case .line: return "战列"
        case .command: return "指挥"
        case .support: return "支援"
        case .siege: return "攻城"
        case .reserve: return "预备"
        case .fleet: return "舰队"
        }
    }
}

public enum LegionFormationReadiness: String, CaseIterable, Identifiable, Equatable, Sendable {
    case fresh
    case steady
    case engaged
    case strained
    case critical

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .fresh: return "整编"
        case .steady: return "稳固"
        case .engaged: return "接战"
        case .strained: return "吃紧"
        case .critical: return "危急"
        }
    }

    fileprivate var priority: Int {
        switch self {
        case .critical: return 5
        case .strained: return 4
        case .engaged: return 3
        case .steady: return 2
        case .fresh: return 1
        }
    }
}

public struct LegionFormationReport: Identifiable, Equatable, Sendable {
    public var unitID: String
    public var faction: Faction
    public var kind: UnitKind
    public var position: Position
    public var role: LegionFormationRole
    public var readiness: LegionFormationReadiness
    public var health: Int
    public var maxHealth: Int
    public var experience: Int
    public var rankName: String
    public var hasGeneral: Bool
    public var generalName: String?
    public var generalTrait: GeneralTrait?
    public var tacticalOrder: TacticalOrder
    public var recommendedOrder: TacticalOrder
    public var attack: Int
    public var defense: Int
    public var movement: Int
    public var adjacentAllyCount: Int
    public var nearbyAllyCount: Int
    public var nearbyEnemyCount: Int
    public var nearbyEnemyFactionCount: Int
    public var skillReady: Bool
    public var skillSummary: String?
    public var formationIntegrityScore: Int
    public var commandSuggestion: String
    public var detail: String

    public var id: String { unitID }
}

public enum TacticalRecommendationKind: String, CaseIterable, Identifiable, Equatable, Sendable {
    case attack
    case reinforce
    case advance
    case hold
    case recover

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .attack: return "压制"
        case .reinforce: return "补线"
        case .advance: return "推进"
        case .hold: return "坚守"
        case .recover: return "整备"
        }
    }
}

public enum TacticalRecommendationRisk: String, CaseIterable, Identifiable, Equatable, Sendable {
    case low
    case guarded
    case high
    case critical

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .low: return "低风险"
        case .guarded: return "谨慎"
        case .high: return "高风险"
        case .critical: return "危急"
        }
    }

    fileprivate var priority: Int {
        switch self {
        case .critical: return 4
        case .high: return 3
        case .guarded: return 2
        case .low: return 1
        }
    }
}

public struct TacticalRecommendationReport: Identifiable, Equatable, Sendable {
    public var unitID: String
    public var faction: Faction
    public var kind: TacticalRecommendationKind
    public var targetPosition: Position
    public var destination: Position
    public var targetUnitID: String?
    public var targetCityID: String?
    public var recommendedOrder: TacticalOrder
    public var path: [Position]
    public var priority: Int
    public var risk: TacticalRecommendationRisk
    public var projectedDamage: Int?
    public var supportDistance: Int?
    public var reason: String
    public var command: String

    public var id: String { unitID }
}

public enum CommanderSynergyKind: String, CaseIterable, Identifiable, Equatable, Sendable {
    case commanderSkill
    case coordinatedAttack
    case reinforce
    case advance
    case recover

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .commanderSkill: return "将令"
        case .coordinatedAttack: return "合击"
        case .reinforce: return "补线"
        case .advance: return "推进"
        case .recover: return "整备"
        }
    }

    fileprivate var priority: Int {
        switch self {
        case .commanderSkill: return 5
        case .coordinatedAttack: return 4
        case .reinforce: return 3
        case .advance: return 2
        case .recover: return 1
        }
    }
}

public enum CommanderSynergyRole: String, CaseIterable, Identifiable, Equatable, Sendable {
    case commander
    case mainEffort
    case support
    case beneficiary
    case reserve

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .commander: return "将领"
        case .mainEffort: return "主攻"
        case .support: return "支援"
        case .beneficiary: return "受益"
        case .reserve: return "预备"
        }
    }
}

public struct CommanderSynergyStepReport: Identifiable, Equatable, Sendable {
    public var unitID: String
    public var faction: Faction
    public var role: CommanderSynergyRole
    public var position: Position
    public var targetPosition: Position
    public var tacticalOrder: TacticalOrder
    public var summary: String
    public var detail: String

    public var id: String { "\(role.rawValue)-\(unitID)" }
}

public struct CommanderSynergyReport: Identifiable, Equatable, Sendable {
    public var id: String
    public var faction: Faction
    public var kind: CommanderSynergyKind
    public var unitID: String
    public var commanderUnitID: String?
    public var targetUnitID: String?
    public var targetCityID: String?
    public var targetPosition: Position
    public var supportingUnitIDs: [String]
    public var beneficiaryUnitIDs: [String]
    public var recommendedOrder: TacticalOrder
    public var formationRole: LegionFormationRole
    public var formationReadiness: LegionFormationReadiness
    public var risk: TacticalRecommendationRisk
    public var projectedDamage: Int?
    public var supportBonus: Int
    public var flankingBonus: Int
    public var commandBonus: Int
    public var projectedRecoveredHealth: Int
    public var projectedFortificationReduction: Int
    public var isExecutable: Bool
    public var blockedReason: String?
    public var score: Int
    public var title: String
    public var summary: String
    public var detail: String
    public var steps: [CommanderSynergyStepReport]
}

public enum BattlefieldFocusKind: String, CaseIterable, Identifiable, Equatable, Sendable {
    case defense
    case generalOpportunity
    case attackOpportunity
    case reinforce
    case advance
    case recover

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .defense: return "救线"
        case .generalOpportunity: return "将领"
        case .attackOpportunity: return "打击"
        case .reinforce: return "补线"
        case .advance: return "推进"
        case .recover: return "整编"
        }
    }
}

public enum BattlefieldFocusSeverity: String, CaseIterable, Identifiable, Equatable, Sendable {
    case watch
    case important
    case urgent
    case critical

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .watch: return "观察"
        case .important: return "重要"
        case .urgent: return "紧急"
        case .critical: return "危急"
        }
    }

    fileprivate var priority: Int {
        switch self {
        case .critical: return 4
        case .urgent: return 3
        case .important: return 2
        case .watch: return 1
        }
    }
}

public struct BattlefieldFocusReport: Identifiable, Equatable, Sendable {
    public var id: String
    public var faction: Faction
    public var kind: BattlefieldFocusKind
    public var severity: BattlefieldFocusSeverity
    public var position: Position
    public var unitID: String?
    public var targetUnitID: String?
    public var targetCityID: String?
    public var relatedUnitIDs: [String]
    public var recommendedOrder: TacticalOrder
    public var score: Int
    public var title: String
    public var summary: String
    public var detail: String
}

public enum MapControlState: String, CaseIterable, Identifiable, Equatable, Sendable {
    case friendlyControlled
    case enemyControlled
    case contested
    case neutral

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .friendlyControlled: return "友军控制"
        case .enemyControlled: return "敌军控制"
        case .contested: return "争夺"
        case .neutral: return "中立"
        }
    }
}

public enum ThreatHeatLevel: String, CaseIterable, Identifiable, Equatable, Sendable {
    case quiet
    case watched
    case contested
    case danger
    case critical

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .quiet: return "安静"
        case .watched: return "监视"
        case .contested: return "争夺"
        case .danger: return "危险"
        case .critical: return "危急"
        }
    }

    fileprivate var priority: Int {
        switch self {
        case .critical: return 5
        case .danger: return 4
        case .contested: return 3
        case .watched: return 2
        case .quiet: return 1
        }
    }
}

public struct MapControlReport: Identifiable, Equatable, Sendable {
    public var position: Position
    public var terrain: TerrainType
    public var perspectiveFaction: Faction
    public var cityID: String?
    public var cityOwner: Faction?
    public var occupantUnitID: String?
    public var occupantFaction: Faction?
    public var friendlyInfluence: Int
    public var enemyInfluence: Int
    public var controlState: MapControlState
    public var threatLevel: ThreatHeatLevel
    public var friendlyUnitIDs: [String]
    public var enemyUnitIDs: [String]
    public var pressureScore: Int
    public var summary: String
    public var detail: String

    public var id: String { "\(position.x)-\(position.y)" }
}

public struct ThreatHeatZoneReport: Identifiable, Equatable, Sendable {
    public var id: String
    public var perspectiveFaction: Faction
    public var center: Position
    public var positions: [Position]
    public var controlState: MapControlState
    public var threatLevel: ThreatHeatLevel
    public var friendlyInfluence: Int
    public var enemyInfluence: Int
    public var sourceUnitIDs: [String]
    public var cityIDs: [String]
    public var attackIntentCount: Int
    public var captureIntentCount: Int
    public var projectedDamageTotal: Int
    public var score: Int
    public var title: String
    public var detail: String
}

public enum AIOperationalPlanKind: String, CaseIterable, Identifiable, Equatable, Sendable {
    case focusedAttack
    case cityCapture
    case commanderSkill
    case advance
    case defend
    case regroup

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .focusedAttack: return "集火"
        case .cityCapture: return "夺城"
        case .commanderSkill: return "将领"
        case .advance: return "推进"
        case .defend: return "固守"
        case .regroup: return "整备"
        }
    }

    fileprivate var priority: Int {
        switch self {
        case .focusedAttack: return 6
        case .cityCapture: return 5
        case .commanderSkill: return 4
        case .advance: return 3
        case .defend: return 2
        case .regroup: return 1
        }
    }
}

public enum AIPlanCoordinationRole: String, CaseIterable, Identifiable, Equatable, Sendable {
    case mainEffort
    case support
    case commander
    case reserve

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .mainEffort: return "主攻"
        case .support: return "支援"
        case .commander: return "将领"
        case .reserve: return "预备"
        }
    }

    fileprivate var priority: Int {
        switch self {
        case .mainEffort: return 4
        case .commander: return 3
        case .support: return 2
        case .reserve: return 1
        }
    }
}

public struct AIPlanStepReport: Identifiable, Equatable, Sendable {
    public var unitID: String
    public var faction: Faction
    public var intentKind: AIIntentKind
    public var coordinationRole: AIPlanCoordinationRole
    public var origin: Position
    public var destination: Position
    public var targetPosition: Position
    public var targetUnitID: String?
    public var targetCityID: String?
    public var tacticalOrder: TacticalOrder
    public var projectedDamage: Int?
    public var threatScore: Int
    public var formationRole: LegionFormationRole?
    public var formationReadiness: LegionFormationReadiness?
    public var generalName: String?
    public var skillSummary: String?
    public var detail: String

    public var id: String { unitID }
}

public struct AIOperationalPlanReport: Identifiable, Equatable, Sendable {
    public var id: String
    public var faction: Faction
    public var kind: AIOperationalPlanKind
    public var targetPosition: Position
    public var targetUnitID: String?
    public var targetCityID: String?
    public var sourceUnitIDs: [String]
    public var commanderUnitIDs: [String]
    public var intentKinds: [AIIntentKind]
    public var pressureLevel: FrontlinePressureLevel?
    public var threatHeatLevel: ThreatHeatLevel?
    public var projectedDamageTotal: Int
    public var score: Int
    public var title: String
    public var summary: String
    public var detail: String
    public var steps: [AIPlanStepReport]
}

public enum FrontlinePressureTargetKind: String, Hashable, Sendable {
    case unit
    case city

    public var displayName: String {
        switch self {
        case .unit: return "部队"
        case .city: return "城市"
        }
    }
}

public enum FrontlinePressureLevel: String, CaseIterable, Identifiable, Equatable, Sendable {
    case watch
    case contested
    case threatened
    case critical

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .watch: return "监视"
        case .contested: return "争夺"
        case .threatened: return "受威胁"
        case .critical: return "危急"
        }
    }
}

public struct FrontlinePressureReport: Identifiable, Equatable, Sendable {
    public var targetID: String
    public var targetKind: FrontlinePressureTargetKind
    public var targetFaction: Faction
    public var targetPosition: Position
    public var sourceFactions: [Faction]
    public var sourceUnitIDs: [String]
    public var intentKinds: [AIIntentKind]
    public var intentCount: Int
    public var attackIntentCount: Int
    public var captureIntentCount: Int
    public var projectedDamageTotal: Int
    public var maxThreatScore: Int
    public var pressureScore: Int
    public var level: FrontlinePressureLevel

    public var id: String { "\(targetKind.rawValue)-\(targetID)" }
}

private struct FrontlinePressureTargetKey: Hashable {
    var kind: FrontlinePressureTargetKind
    var id: String
}

private struct AIOperationalPlanKey: Hashable {
    var faction: Faction
    var kind: AIOperationalPlanKind
    var targetPosition: Position
    var targetUnitID: String?
    var targetCityID: String?
}

private struct FrontlinePressureTarget {
    var key: FrontlinePressureTargetKey
    var faction: Faction
    var position: Position
    var health: Int?
}

private struct FrontlinePressureAccumulator {
    var target: FrontlinePressureTarget
    var sourceFactions: [Faction] = []
    var sourceUnitIDs: [String] = []
    var intentKinds: [AIIntentKind] = []
    var intentCount = 0
    var attackIntentCount = 0
    var captureIntentCount = 0
    var projectedDamageTotal = 0
    var maxThreatScore = 0

    mutating func add(_ intent: AIIntent) {
        intentCount += 1
        if !sourceFactions.contains(intent.faction) {
            sourceFactions.append(intent.faction)
        }
        if !sourceUnitIDs.contains(intent.unitID) {
            sourceUnitIDs.append(intent.unitID)
        }
        intentKinds.append(intent.kind)
        if intent.kind.isAttackPressure {
            attackIntentCount += 1
        }
        if intent.kind == .captureCity {
            captureIntentCount += 1
        }
        projectedDamageTotal += intent.projectedDamage ?? 0
        maxThreatScore = max(maxThreatScore, intent.threatScore)
    }

    var pressureScore: Int {
        maxThreatScore +
            projectedDamageTotal * 4 +
            attackIntentCount * 80 +
            captureIntentCount * 140 +
            max(0, intentCount - 1) * 60
    }

    var level: FrontlinePressureLevel {
        if captureIntentCount > 0 ||
            attackIntentCount >= 2 ||
            target.health.map({ projectedDamageTotal >= $0 }) == true {
            return .critical
        }

        if attackIntentCount > 0 ||
            maxThreatScore >= 420 ||
            pressureScore >= 620 {
            return .threatened
        }

        if intentKinds.contains(where: { $0 == .advance || $0 == .useSkill }) ||
            maxThreatScore >= 240 {
            return .contested
        }

        return .watch
    }

    var report: FrontlinePressureReport {
        FrontlinePressureReport(
            targetID: target.key.id,
            targetKind: target.key.kind,
            targetFaction: target.faction,
            targetPosition: target.position,
            sourceFactions: sourceFactions,
            sourceUnitIDs: sourceUnitIDs,
            intentKinds: intentKinds,
            intentCount: intentCount,
            attackIntentCount: attackIntentCount,
            captureIntentCount: captureIntentCount,
            projectedDamageTotal: projectedDamageTotal,
            maxThreatScore: maxThreatScore,
            pressureScore: pressureScore,
            level: level
        )
    }
}

private extension AIIntentKind {
    var isAttackPressure: Bool {
        self == .attack || self == .advanceAttack
    }
}

private struct CombatModifiers {
    var supportBonus: Int
    var flankingBonus: Int
    var commandBonus: Int
    var defenderSupportBonus: Int

    var attackTotal: Int {
        supportBonus + flankingBonus + commandBonus
    }
}

public enum GameRuleError: Error, Equatable, Sendable {
    case notActiveFaction
    case unitAlreadyMoved
    case unitAlreadyActed
    case invalidDestination
    case invalidTarget
    case occupiedTile
    case cityNotOwned
    case insufficientResources
    case technologyAlreadyResearched
    case generalAlreadyAssigned
    case invalidDiplomacyTarget
    case protectedByTreaty
    case noSupply
    case generalSkillUnavailable
    case generalSkillOnCooldown
    case campaignAlreadyEnded
    case missingEntity

    public var displayMessage: String {
        switch self {
        case .notActiveFaction: return "当前不是该阵营回合"
        case .unitAlreadyMoved: return "该单位已经移动"
        case .unitAlreadyActed: return "该单位已经行动"
        case .invalidDestination: return "无法移动到该地块"
        case .invalidTarget: return "目标不在攻击范围"
        case .occupiedTile: return "目标地块已被占用"
        case .cityNotOwned: return "只能在己方城市执行该操作"
        case .insufficientResources: return "资源不足"
        case .technologyAlreadyResearched: return "科技已经研发"
        case .generalAlreadyAssigned: return "该军团已有将领"
        case .invalidDiplomacyTarget: return "无法对该阵营派出使节"
        case .protectedByTreaty: return "停战或同盟关系下不能攻击"
        case .noSupply: return "当前位置没有可用补给"
        case .generalSkillUnavailable: return "该单位没有可用将领技能"
        case .generalSkillOnCooldown: return "将领技能仍在冷却"
        case .campaignAlreadyEnded: return "战役已结束，不能继续改变战局"
        case .missingEntity: return "目标不存在"
        }
    }
}

public struct GameState: Codable, Equatable, Sendable {
    public var mode: GameMode
    public var turn: Int
    public var activeFaction: Faction
    public var width: Int
    public var height: Int
    public var tiles: [Tile]
    public var cities: [City]
    public var units: [ArmyUnit]
    public var resources: [Faction: EmpireResources]
    public var researchedTechnologies: [Faction: Set<Technology>]
    public var diplomaticRelations: [DiplomaticRelation]
    public var missions: [Mission]
    public var eventLog: [String]

    private static let cityDevelopmentCost = EmpireResources(gold: 70, grain: 40, iron: 35, science: 0, prestige: 0)
    private static let cityDevelopmentProductionIncrease = EmpireResources(gold: 10, grain: 8, iron: 6, science: 4, prestige: 1)
    private static let cityDevelopmentFortificationIncrease = 3

    public init(
        mode: GameMode,
        turn: Int,
        activeFaction: Faction,
        width: Int,
        height: Int,
        tiles: [Tile],
        cities: [City],
        units: [ArmyUnit],
        resources: [Faction: EmpireResources],
        researchedTechnologies: [Faction: Set<Technology>],
        diplomaticRelations: [DiplomaticRelation],
        missions: [Mission],
        eventLog: [String] = []
    ) {
        self.mode = mode
        self.turn = turn
        self.activeFaction = activeFaction
        self.width = width
        self.height = height
        self.tiles = tiles
        self.cities = cities
        self.units = units
        self.resources = resources
        self.researchedTechnologies = researchedTechnologies
        self.diplomaticRelations = diplomaticRelations
        self.missions = missions
        self.eventLog = eventLog
    }

    public static func newCampaign(mode: GameMode = .campaign) -> GameState {
        var tiles: [Tile] = []
        let width = 12
        let height = 8

        for y in 0..<height {
            for x in 0..<width {
                let position = Position(x: x, y: y)
                var terrain: TerrainType = .plains

                if (y >= 5 && x <= 6) || (y >= 4 && x >= 8) || (y == 3 && x == 6) {
                    terrain = .water
                } else if y == 2 && (2...8).contains(x) {
                    terrain = .road
                } else if (x == 1 && y == 1) || (x == 8 && y == 1) || (x == 10 && y == 2) {
                    terrain = .forest
                } else if (x == 4 && y == 1) || (x == 7 && y == 4) || (x == 11 && y == 1) {
                    terrain = .hills
                }

                tiles.append(Tile(position: position, terrain: terrain))
            }
        }

        let cityData: [City] = [
            City(id: "rome", name: "罗马", position: Position(x: 3, y: 3), owner: .rome, production: EmpireResources(gold: 45, grain: 30, iron: 20, science: 12, prestige: 2), fortification: 12),
            City(id: "neapolis", name: "那不勒斯", position: Position(x: 4, y: 4), owner: .rome, production: EmpireResources(gold: 28, grain: 22, iron: 12, science: 6, prestige: 1), fortification: 8),
            City(id: "massilia", name: "马赛", position: Position(x: 5, y: 2), owner: .neutral, production: EmpireResources(gold: 30, grain: 20, iron: 16, science: 10, prestige: 1), fortification: 8),
            City(id: "alesia", name: "阿莱西亚", position: Position(x: 8, y: 2), owner: .gaul, production: EmpireResources(gold: 32, grain: 28, iron: 18, science: 8, prestige: 1), fortification: 9),
            City(id: "carthage", name: "迦太基", position: Position(x: 2, y: 6), owner: .carthage, production: EmpireResources(gold: 48, grain: 22, iron: 24, science: 10, prestige: 2), fortification: 13),
            City(id: "syracuse", name: "叙拉古", position: Position(x: 6, y: 6), owner: .neutral, production: EmpireResources(gold: 35, grain: 20, iron: 14, science: 10, prestige: 1), fortification: 9),
            City(id: "alexandria", name: "亚历山大", position: Position(x: 10, y: 6), owner: .egypt, production: EmpireResources(gold: 40, grain: 34, iron: 12, science: 16, prestige: 2), fortification: 10)
        ]

        for city in cityData {
            if let index = tiles.firstIndex(where: { $0.position == city.position }) {
                tiles[index].terrain = .city
            }
        }

        let units: [ArmyUnit] = [
            ArmyUnit(id: "rome-legion-1", kind: .legion, faction: .rome, position: Position(x: 3, y: 3), experience: 1, generalName: "凯撒", generalTrait: .eagleStandard),
            ArmyUnit(id: "rome-cavalry-1", kind: .cavalry, faction: .rome, position: Position(x: 4, y: 4), experience: 0, generalName: "拉比埃努斯", generalTrait: .quartermaster),
            ArmyUnit(id: "rome-archer-1", kind: .archer, faction: .rome, position: Position(x: 2, y: 2)),
            ArmyUnit(id: "carthage-legion-1", kind: .legion, faction: .carthage, position: Position(x: 2, y: 6), experience: 1, generalName: "汉尼拔", generalTrait: .siegeEngineer),
            ArmyUnit(id: "carthage-navy-1", kind: .navy, faction: .carthage, position: Position(x: 4, y: 6)),
            ArmyUnit(id: "gaul-legion-1", kind: .legion, faction: .gaul, position: Position(x: 8, y: 2), generalName: "维钦托利", generalTrait: .shieldWall),
            ArmyUnit(id: "egypt-archer-1", kind: .archer, faction: .egypt, position: Position(x: 10, y: 6))
        ]

        var resources: [Faction: EmpireResources] = [:]
        for faction in Faction.turnOrder {
            resources[faction] = EmpireResources(gold: 180, grain: 120, iron: 90, science: 70, prestige: 6)
        }

        let missions = [
            Mission(
                id: "secure-sicily",
                title: "夺取西西里",
                objective: "占领叙拉古",
                requirement: .controlCity(cityID: "syracuse", faction: .rome),
                reward: EmpireResources(gold: 80, grain: 30, iron: 25, science: 10, prestige: 2)
            ),
            Mission(
                id: "raise-legions",
                title: "扩充军团",
                objective: "拥有 5 支罗马部队",
                requirement: .factionUnitCount(faction: .rome, atLeast: 5),
                reward: EmpireResources(gold: 40, grain: 50, iron: 25, science: 8, prestige: 1)
            ),
            Mission(
                id: "break-carthage",
                title: "压制迦太基",
                objective: "占领迦太基",
                requirement: .controlCity(cityID: "carthage", faction: .rome),
                reward: EmpireResources(gold: 120, grain: 60, iron: 45, science: 20, prestige: 4)
            )
        ]

        return GameState(
            mode: mode,
            turn: 1,
            activeFaction: .rome,
            width: width,
            height: height,
            tiles: tiles,
            cities: cityData,
            units: units,
            resources: resources,
            researchedTechnologies: Dictionary(uniqueKeysWithValues: Faction.turnOrder.map { ($0, Set<Technology>()) }),
            diplomaticRelations: [
                DiplomaticRelation(first: .rome, second: .carthage, status: .war),
                DiplomaticRelation(first: .rome, second: .gaul, status: .war),
                DiplomaticRelation(first: .rome, second: .egypt, status: .truce),
                DiplomaticRelation(first: .carthage, second: .gaul, status: .war),
                DiplomaticRelation(first: .carthage, second: .egypt, status: .war),
                DiplomaticRelation(first: .gaul, second: .egypt, status: .truce)
            ],
            missions: missions,
            eventLog: ["元老院命令：确保罗马在地中海的补给线。"]
        )
    }

    public var campaignStatus: CampaignStatus {
        if !cities.contains(where: { $0.owner == .rome }) {
            return CampaignStatus(
                kind: .romanDefeat,
                title: CampaignStatusKind.romanDefeat.displayName,
                detail: "罗马失去所有城市，元老院撤回战役授权。"
            )
        }

        let objectives = campaignObjectiveMissions
        if !objectives.isEmpty, objectives.allSatisfy({ isMissionFulfilled($0) }) {
            return CampaignStatus(
                kind: .romanVictory,
                title: CampaignStatusKind.romanVictory.displayName,
                detail: "所有元老院战役目标已经完成。"
            )
        }

        if let mission = objectives.first(where: { !isMissionFulfilled($0) }) ?? missions.first(where: { !$0.isCompleted }) {
            return CampaignStatus(
                kind: .ongoing,
                title: CampaignStatusKind.ongoing.displayName,
                detail: "当前目标：\(mission.objective)",
                primaryMissionID: mission.id,
                progressText: missionProgressText(for: mission)
            )
        }

        return CampaignStatus(
            kind: .ongoing,
            title: CampaignStatusKind.ongoing.displayName,
            detail: "稳固地中海战线，等待元老院新命令。"
        )
    }

    public func tile(at position: Position) -> Tile? {
        tiles.first { $0.position == position }
    }

    public func city(at position: Position) -> City? {
        cities.first { $0.position == position }
    }

    public func unit(at position: Position) -> ArmyUnit? {
        units.first { $0.position == position }
    }

    public func unit(withID id: String) -> ArmyUnit? {
        units.first { $0.id == id }
    }

    public func city(withID id: String) -> City? {
        cities.first { $0.id == id }
    }

    public func income(for faction: Faction) -> EmpireResources {
        cities
            .filter { $0.owner == faction }
            .reduce(.zero) { partial, city in
                var next = partial
                next.add(city.production)
                return next
            }
    }

    public func cityDevelopmentPreview(id cityID: String) throws -> CityDevelopmentPreview {
        guard let city = city(withID: cityID) else {
            throw GameRuleError.missingEntity
        }

        let cost = Self.cityDevelopmentCost
        var projectedProduction = city.production
        projectedProduction.add(Self.cityDevelopmentProductionIncrease)
        let projectedFortification = city.fortification + Self.cityDevelopmentFortificationIncrease
        let blockingError: GameRuleError?

        if campaignStatus.isGameOver {
            blockingError = .campaignAlreadyEnded
        } else if city.owner != activeFaction {
            blockingError = .cityNotOwned
        } else if !(resources[activeFaction] ?? .zero).canPay(cost) {
            blockingError = .insufficientResources
        } else {
            blockingError = nil
        }

        return CityDevelopmentPreview(
            cityID: city.id,
            cityName: city.name,
            owner: city.owner,
            cost: cost,
            productionIncrease: Self.cityDevelopmentProductionIncrease,
            projectedProduction: projectedProduction,
            fortificationIncrease: Self.cityDevelopmentFortificationIncrease,
            projectedFortification: projectedFortification,
            canDevelop: blockingError == nil,
            blockedReason: blockingError?.displayMessage,
            blockingError: blockingError
        )
    }

    public func recruitmentPreview(_ kind: UnitKind, at cityID: String) throws -> CityRecruitmentPreview {
        guard let city = city(withID: cityID) else {
            throw GameRuleError.missingEntity
        }

        let cost = kind.recruitmentCost
        let deploymentPosition: Position?
        let blockingError: GameRuleError?

        if campaignStatus.isGameOver {
            deploymentPosition = nil
            blockingError = .campaignAlreadyEnded
        } else if city.owner != activeFaction {
            deploymentPosition = nil
            blockingError = .cityNotOwned
        } else {
            do {
                deploymentPosition = try spawnPosition(for: kind, from: city)
                if (resources[activeFaction] ?? .zero).canPay(cost) {
                    blockingError = nil
                } else {
                    blockingError = .insufficientResources
                }
            } catch let error as GameRuleError {
                deploymentPosition = nil
                blockingError = error
            } catch {
                deploymentPosition = nil
                blockingError = .invalidDestination
            }
        }

        return CityRecruitmentPreview(
            cityID: city.id,
            cityName: city.name,
            owner: city.owner,
            kind: kind,
            cost: cost,
            deploymentPosition: deploymentPosition,
            canRecruit: blockingError == nil,
            blockedReason: recruitmentBlockedReason(for: kind, from: city, error: blockingError),
            blockingError: blockingError
        )
    }

    public func diplomaticStatus(between first: Faction, and second: Faction) -> DiplomaticStatus {
        guard first != second else {
            return .alliance
        }

        guard first != .neutral, second != .neutral else {
            return .truce
        }

        return diplomaticRelations
            .first { $0.id == DiplomaticRelation.id(for: first, second) }?
            .status ?? .war
    }

    public func reachablePositions(for unitID: String) -> Set<Position> {
        guard let unit = unit(withID: unitID),
              unit.faction == activeFaction,
              !unit.hasMoved else {
            return []
        }

        return reachablePositions(for: unit)
    }

    private func reachablePositions(for unit: ArmyUnit) -> Set<Position> {
        var bestCost: [Position: Int] = [unit.position: 0]
        var frontier = [unit.position]

        while !frontier.isEmpty {
            let current = frontier.removeFirst()
            let currentCost = bestCost[current] ?? 0

            for neighbor in current.neighbors(width: width, height: height) {
                guard let tile = tile(at: neighbor),
                      unit.kind.canEnter(tile.terrain),
                      self.unit(at: neighbor) == nil else {
                    continue
                }

                let nextCost = currentCost + tile.terrain.movementCost
                guard nextCost <= effectiveMovement(for: unit) else {
                    continue
                }

                if nextCost < (bestCost[neighbor] ?? Int.max) {
                    bestCost[neighbor] = nextCost
                    frontier.append(neighbor)
                }
            }
        }

        return Set(bestCost.keys).subtracting([unit.position])
    }

    public func effectiveMovement(for unit: ArmyUnit) -> Int {
        max(1, unit.kind.movement + (unit.resolvedGeneralTrait?.movementBonus ?? 0) + unit.resolvedTacticalOrder.movementBonus)
    }

    public func effectiveAttack(for unit: ArmyUnit) -> Int {
        let known = researchedTechnologies[unit.faction] ?? []
        var value = unit.kind.attack

        if known.contains(.marchingDrill), unit.kind != .navy {
            value += 4
        }

        if known.contains(.navalCommand), unit.kind == .navy {
            value += 6
        }

        value += unit.resolvedGeneralTrait?.attackBonus ?? 0
        value += unit.resolvedTacticalOrder.attackBonus
        return max(1, value)
    }

    public func warMeritStatus(for unit: ArmyUnit) -> WarMeritStatus {
        WarMeritStatus(experience: unit.experience)
    }

    public func warMeritStatus(unitID: String) throws -> WarMeritStatus {
        guard let unit = unit(withID: unitID) else {
            throw GameRuleError.missingEntity
        }

        return warMeritStatus(for: unit)
    }

    public func legionFormationReport(unitID: String) throws -> LegionFormationReport {
        guard let unit = unit(withID: unitID) else {
            throw GameRuleError.missingEntity
        }

        return legionFormationReport(for: unit)
    }

    public func legionFormationReports(
        for faction: Faction = .rome,
        limit: Int = 6
    ) -> [LegionFormationReport] {
        guard faction != .neutral,
              limit > 0 else {
            return []
        }

        return units
            .filter { $0.faction == faction }
            .map { legionFormationReport(for: $0) }
            .sorted { left, right in
                let leftPriority = legionFormationPriority(for: left)
                let rightPriority = legionFormationPriority(for: right)
                if leftPriority == rightPriority {
                    return left.unitID < right.unitID
                }
                return leftPriority > rightPriority
            }
            .prefix(limit)
            .map { $0 }
    }

    public func tacticalRecommendation(unitID: String) throws -> TacticalRecommendationReport {
        guard let unit = unit(withID: unitID) else {
            throw GameRuleError.missingEntity
        }

        return tacticalRecommendation(for: unit)
    }

    public func commanderSynergyReport(unitID: String) throws -> CommanderSynergyReport {
        guard let unit = unit(withID: unitID) else {
            throw GameRuleError.missingEntity
        }

        return commanderSynergyReport(for: unit)
    }

    public func commanderSynergyReports(
        for faction: Faction = .rome,
        limit: Int = 5
    ) -> [CommanderSynergyReport] {
        guard faction != .neutral,
              limit > 0 else {
            return []
        }

        return units
            .filter { $0.faction == faction }
            .map { commanderSynergyReport(for: $0) }
            .sorted { left, right in
                if left.score == right.score {
                    return left.id < right.id
                }
                return left.score > right.score
            }
            .prefix(limit)
            .map { $0 }
    }

    public func battlefieldFocusReports(
        for faction: Faction = .rome,
        limit: Int = 5
    ) -> [BattlefieldFocusReport] {
        guard faction != .neutral,
              limit > 0 else {
            return []
        }

        let formationReports = units
            .filter { $0.faction == faction }
            .map { legionFormationReport(for: $0) }

        var reports: [BattlefieldFocusReport] = []
        reports.append(contentsOf: battlefieldPressureFocusReports(for: faction))
        reports.append(contentsOf: formationReports.compactMap(battlefieldGeneralOpportunityFocus(for:)))
        reports.append(contentsOf: formationReports.compactMap(battlefieldRecoveryFocus(for:)))

        let recommendations = units
            .filter { $0.faction == faction }
            .map { tacticalRecommendation(for: $0) }
        reports.append(contentsOf: recommendations.compactMap(battlefieldTacticalFocus(for:)))

        return reports
            .sorted { left, right in
                if left.score == right.score {
                    return left.id < right.id
                }
                return left.score > right.score
            }
            .prefix(limit)
            .map { $0 }
    }

    public func battlefieldFocusReport(for faction: Faction = .rome) -> BattlefieldFocusReport? {
        battlefieldFocusReports(for: faction, limit: 1).first
    }

    public func mapControlReport(at position: Position, for faction: Faction = .rome) -> MapControlReport? {
        guard faction != .neutral,
              tile(at: position) != nil else {
            return nil
        }

        let pressureByPosition = frontlinePressureByPosition(against: faction)
        return mapControlReport(at: position, for: faction, pressure: pressureByPosition[position])
    }

    public func mapControlReports(for faction: Faction = .rome) -> [MapControlReport] {
        guard faction != .neutral else {
            return []
        }

        let pressureByPosition = frontlinePressureByPosition(against: faction)

        return tiles
            .sorted { left, right in
                if left.position.y == right.position.y {
                    return left.position.x < right.position.x
                }
                return left.position.y < right.position.y
            }
            .map { tile in
                mapControlReport(at: tile.position, for: faction, pressure: pressureByPosition[tile.position])
            }
    }

    public func threatHeatZoneReports(
        for faction: Faction = .rome,
        limit: Int = 5
    ) -> [ThreatHeatZoneReport] {
        guard faction != .neutral,
              limit > 0 else {
            return []
        }

        let controlReports = mapControlReports(for: faction)
        let pressureByPosition = frontlinePressureByPosition(against: faction)

        return controlReports
            .compactMap { report -> ThreatHeatZoneReport? in
                guard report.threatLevel != .quiet,
                      report.enemyInfluence > 0 || report.pressureScore > 0 else {
                    return nil
                }

                return threatHeatZoneReport(from: report, pressure: pressureByPosition[report.position])
            }
            .sorted { left, right in
                if left.score == right.score {
                    if left.center.y == right.center.y {
                        if left.center.x == right.center.x {
                            return left.id < right.id
                        }
                        return left.center.x < right.center.x
                    }
                    return left.center.y < right.center.y
                }
                return left.score > right.score
            }
            .prefix(limit)
            .map { $0 }
    }

    public func aiOperationalPlanReports(
        against defendingFaction: Faction = .rome,
        perFactionLimit: Int = 4,
        limit: Int = 5
    ) -> [AIOperationalPlanReport] {
        guard defendingFaction != .neutral,
              perFactionLimit > 0,
              limit > 0 else {
            return []
        }

        let candidateLimit = max(perFactionLimit * 2, limit * 3, 8)
        let pressureReports = frontlinePressureReports(
            against: defendingFaction,
            perFactionLimit: candidateLimit,
            limit: max(limit * 2, 6)
        )
        let heatReports = threatHeatZoneReports(for: defendingFaction, limit: max(limit * 2, 6))
        var stepsByKey: [AIOperationalPlanKey: [AIPlanStepReport]] = [:]

        for faction in Faction.turnOrder where faction != defendingFaction && faction != .neutral {
            guard diplomaticStatus(between: defendingFaction, and: faction) == .war else {
                continue
            }

            let forecast = aiPlanningForecast(for: faction)
            for intent in forecast.aiIntentReports(for: faction, limit: candidateLimit) {
                guard let unit = forecast.unit(withID: intent.unitID) else {
                    continue
                }

                let targetPosition = aiOperationalTargetPosition(for: intent, fallback: unit.position)
                let kind = aiOperationalPlanKind(for: intent)
                let key = AIOperationalPlanKey(
                    faction: faction,
                    kind: kind,
                    targetPosition: targetPosition,
                    targetUnitID: intent.targetUnitID,
                    targetCityID: intent.targetCityID
                )
                let step = forecast.aiPlanStepReport(for: intent, unit: unit, targetPosition: targetPosition)
                stepsByKey[key, default: []].append(step)
            }
        }

        return stepsByKey
            .map { key, steps in
                let pressure = aiOperationalPressure(for: key, in: pressureReports)
                let heat = aiOperationalHeat(for: key.targetPosition, in: heatReports)
                return aiOperationalPlanReport(for: key, steps: steps, pressure: pressure, heat: heat)
            }
            .sorted { left, right in
                if left.score == right.score {
                    return left.id < right.id
                }
                return left.score > right.score
            }
            .prefix(limit)
            .map { $0 }
    }

    public func aiOperationalPlanReport(against defendingFaction: Faction = .rome) -> AIOperationalPlanReport? {
        aiOperationalPlanReports(against: defendingFaction, perFactionLimit: 4, limit: 1).first
    }

    public func effectiveDefense(for unit: ArmyUnit) -> Int {
        max(1, unit.kind.defense + (unit.resolvedGeneralTrait?.defenseBonus ?? 0) + unit.resolvedTacticalOrder.defenseBonus)
    }

    private func tacticalRecommendation(for unit: ArmyUnit) -> TacticalRecommendationReport {
        let formation = legionFormationReport(for: unit)

        if let attackReport = tacticalAttackRecommendation(for: unit, formation: formation) {
            return attackReport
        }

        if let reinforceReport = tacticalReinforceRecommendation(for: unit, formation: formation) {
            return reinforceReport
        }

        if let advanceReport = tacticalAdvanceRecommendation(for: unit, formation: formation) {
            return advanceReport
        }

        return tacticalHoldRecommendation(for: unit, formation: formation)
    }

    private func tacticalAttackRecommendation(
        for unit: ArmyUnit,
        formation: LegionFormationReport
    ) -> TacticalRecommendationReport? {
        guard unit.faction == activeFaction,
              !unit.hasActed else {
            return nil
        }

        let candidates = attackTargets(for: unit).compactMap { target -> (unit: ArmyUnit, preview: CombatPreview, score: Int)? in
            guard let preview = try? attackPreview(attackerID: unit.id, defenderID: target.id) else {
                return nil
            }

            let score = (preview.defeatsDefender ? 1_000 : 0) +
                preview.damage * 12 -
                preview.retaliation * 7 +
                max(0, target.kind.maxHealth - target.health) * 2 +
                (target.generalName == nil ? 0 : 90)
            return (target, preview, score)
        }

        guard let best = candidates.sorted(by: { left, right in
            if left.score == right.score {
                return left.unit.id < right.unit.id
            }
            return left.score > right.score
        }).first else {
            return nil
        }

        let risk = tacticalRisk(for: unit, preview: best.preview)
        let order: TacticalOrder = best.preview.defeatsDefender && unit.healthRatio >= 0.55 ? .assault : formation.recommendedOrder
        let command = best.preview.defeatsDefender
            ? "集中攻击，争取击溃\(best.unit.faction.displayName)\(best.unit.kind.displayName)。"
            : "压制\(best.unit.faction.displayName)\(best.unit.kind.displayName)，预计伤害 \(best.preview.damage)。"

        return TacticalRecommendationReport(
            unitID: unit.id,
            faction: unit.faction,
            kind: .attack,
            targetPosition: best.unit.position,
            destination: unit.position,
            targetUnitID: best.unit.id,
            targetCityID: nil,
            recommendedOrder: order,
            path: tacticalFallbackPath(from: unit.position, to: best.unit.position),
            priority: 700 + best.score - risk.priority * 30,
            risk: risk,
            projectedDamage: best.preview.damage,
            supportDistance: nil,
            reason: "当前射程内存在可打击目标，反击 \(best.preview.retaliation)。",
            command: command
        )
    }

    private func tacticalReinforceRecommendation(
        for unit: ArmyUnit,
        formation: LegionFormationReport
    ) -> TacticalRecommendationReport? {
        guard unit.faction == activeFaction,
              !unit.hasMoved else {
            return nil
        }

        let reachable = tacticalReachableDestinations(for: unit)
        guard !reachable.isEmpty else { return nil }

        let pressureReports = frontlinePressureReports(against: unit.faction, perFactionLimit: 4, limit: 4)
            .filter { report in
                report.targetID != unit.id &&
                    report.level != .watch
            }

        guard let pressure = pressureReports.first,
              let destination = tacticalBestDestination(from: reachable, toward: pressure.targetPosition, for: unit),
              destination.hexDistance(to: pressure.targetPosition) < unit.position.hexDistance(to: pressure.targetPosition) else {
            return nil
        }

        let risk: TacticalRecommendationRisk = pressure.level == .critical ? .high : .guarded
        let path = tacticalPath(from: unit.position, to: destination, for: unit) ?? tacticalFallbackPath(from: unit.position, to: destination)
        let targetUnitID = pressure.targetKind == .unit ? pressure.targetID : nil
        let targetCityID = pressure.targetKind == .city ? pressure.targetID : nil
        let distance = destination.hexDistance(to: pressure.targetPosition)

        return TacticalRecommendationReport(
            unitID: unit.id,
            faction: unit.faction,
            kind: .reinforce,
            targetPosition: pressure.targetPosition,
            destination: destination,
            targetUnitID: targetUnitID,
            targetCityID: targetCityID,
            recommendedOrder: distance <= 1 ? .defensive : formation.recommendedOrder,
            path: path,
            priority: 560 + pressure.pressureScore - distance * 25,
            risk: risk,
            projectedDamage: nil,
            supportDistance: distance,
            reason: "\(pressure.targetKind.displayName)承受\(pressure.level.displayName)压力，需靠拢补线。",
            command: "移动至 \(destination)，把战线距离压到 \(distance) 格。"
        )
    }

    private func tacticalAdvanceRecommendation(
        for unit: ArmyUnit,
        formation: LegionFormationReport
    ) -> TacticalRecommendationReport? {
        guard unit.faction == activeFaction,
              !unit.hasMoved else {
            return nil
        }

        let reachable = tacticalReachableDestinations(for: unit)
        guard !reachable.isEmpty,
              let city = nearestAICityObjective(from: unit.position, for: unit.faction),
              let destination = tacticalBestDestination(from: reachable, toward: city.position, for: unit),
              destination != unit.position else {
            return nil
        }

        let distance = destination.hexDistance(to: city.position)
        let path = tacticalPath(from: unit.position, to: destination, for: unit) ?? tacticalFallbackPath(from: unit.position, to: destination)
        let risk: TacticalRecommendationRisk = nearbyEnemyUnits(for: unit, range: 3).isEmpty ? .low : .guarded

        return TacticalRecommendationReport(
            unitID: unit.id,
            faction: unit.faction,
            kind: .advance,
            targetPosition: city.position,
            destination: destination,
            targetUnitID: nil,
            targetCityID: city.id,
            recommendedOrder: distance > 1 ? .forcedMarch : formation.recommendedOrder,
            path: path,
            priority: 360 + max(0, 8 - distance) * 18,
            risk: risk,
            projectedDamage: nil,
            supportDistance: distance,
            reason: "\(city.name)是最近可争夺城市，当前可向其推进。",
            command: "向\(city.name)推进至 \(destination)，距离目标 \(distance) 格。"
        )
    }

    private func tacticalHoldRecommendation(
        for unit: ArmyUnit,
        formation: LegionFormationReport
    ) -> TacticalRecommendationReport {
        let shouldRecover = unit.healthRatio <= 0.58 || unit.hasActed || unit.hasMoved
        let kind: TacticalRecommendationKind = shouldRecover ? .recover : .hold
        let risk: TacticalRecommendationRisk

        if formation.readiness == .critical {
            risk = .critical
        } else if formation.readiness == .strained {
            risk = .high
        } else if formation.nearbyEnemyCount > 0 {
            risk = .guarded
        } else {
            risk = .low
        }

        let command = shouldRecover
            ? "保持阵位并整备，优先恢复行动能力。"
            : "维持\(formation.recommendedOrder.displayName)姿态，等待更明确目标。"

        return TacticalRecommendationReport(
            unitID: unit.id,
            faction: unit.faction,
            kind: kind,
            targetPosition: unit.position,
            destination: unit.position,
            targetUnitID: nil,
            targetCityID: city(at: unit.position)?.id,
            recommendedOrder: formation.recommendedOrder,
            path: [unit.position],
            priority: 180 + max(0, 100 - formation.formationIntegrityScore) + risk.priority * 25,
            risk: risk,
            projectedDamage: nil,
            supportDistance: 0,
            reason: formation.commandSuggestion,
            command: command
        )
    }

    private func commanderSynergyReport(for unit: ArmyUnit) -> CommanderSynergyReport {
        let formation = legionFormationReport(for: unit)
        let recommendation = tacticalRecommendation(for: unit)
        var candidates: [CommanderSynergyReport] = []
        var blockedUsefulSkillReport: CommanderSynergyReport?

        if let skillReport = commanderSkillSynergyReport(for: unit, formation: formation) {
            if skillReport.isExecutable {
                candidates.append(skillReport)
            } else if skillReport.projectedRecoveredHealth > 0 || skillReport.projectedFortificationReduction > 0 {
                blockedUsefulSkillReport = skillReport
            } else {
                candidates.append(skillReport)
            }
        }

        if let attackReport = commanderAttackSynergyReport(for: unit, formation: formation) {
            candidates.append(attackReport)
        }

        if recommendation.kind != .attack {
            candidates.append(commanderRecommendationSynergyReport(for: unit, formation: formation, recommendation: recommendation))
        }

        let bestReport = candidates
            .sorted { left, right in
                if left.score == right.score {
                    return left.id < right.id
                }
                return left.score > right.score
            }
            .first

        if let blockedUsefulSkillReport,
           bestReport?.kind != .coordinatedAttack {
            return blockedUsefulSkillReport
        }

        return bestReport ??
            blockedUsefulSkillReport ??
            commanderRecommendationSynergyReport(for: unit, formation: formation, recommendation: recommendation)
    }

    private func commanderSkillSynergyReport(
        for unit: ArmyUnit,
        formation: LegionFormationReport
    ) -> CommanderSynergyReport? {
        guard unit.generalName != nil,
              let trait = unit.resolvedGeneralTrait else {
            return nil
        }

        let preview = generalSkillPreview(for: unit)
        let usefulEffect = preview.projectedRecoveredHealth > 0 || preview.projectedFortificationReduction > 0
        let isExecutable = preview.isExecutable && usefulEffect
        let targetUnitID = preview.affectedUnitIDs.first
        let targetCityID = preview.affectedCityIDs.first
        let targetPosition = targetUnitID
            .flatMap { self.unit(withID: $0)?.position } ??
            targetCityID.flatMap { city(withID: $0)?.position } ??
            preview.affectedPositions.first ??
            unit.position
        let beneficiaryUnitIDs = preview.affectedUnitIDs
        let supportingUnitIDs = nearbyAlliedUnits(for: unit, range: max(1, trait.commandRange))
            .map(\.id)
        let risk = commanderSynergyRisk(for: formation.readiness)
        let targetName = battlefieldTargetName(
            unitID: targetUnitID,
            cityID: targetCityID,
            fallback: targetPosition.description
        )
        let blockedReason = isExecutable ? nil : (preview.blockedReason ?? preview.summary)
        let executionScore: Int
        if isExecutable {
            executionScore = 720
        } else if usefulEffect {
            executionScore = -360
        } else {
            executionScore = -460
        }
        let score = executionScore +
            CommanderSynergyKind.commanderSkill.priority * 110 +
            preview.projectedRecoveredHealth * 3 +
            preview.projectedFortificationReduction * 22 +
            beneficiaryUnitIDs.count * 30 +
            formation.readiness.priority * 35 +
            max(0, 100 - formation.formationIntegrityScore)
        let steps = commanderSynergySteps(
            unit: unit,
            role: .commander,
            targetPosition: targetPosition,
            recommendedOrder: formation.recommendedOrder,
            summary: trait.skillName,
            detail: preview.detail,
            extraUnits: beneficiaryUnitIDs.compactMap { self.unit(withID: $0) },
            extraRole: .beneficiary,
            extraDetail: "受益于\(trait.skillName)"
        )
        let impact = preview.projectedRecoveredHealth > 0
            ? "预计恢复 \(preview.projectedRecoveredHealth)"
            : "削城防 \(preview.projectedFortificationReduction)"
        let title = "\(unit.generalName ?? "将领")\(trait.skillName)"
        let summary = isExecutable ? "\(impact) · \(targetName)" : "不可执行 · \(blockedReason ?? "无有效目标")"
        let detail = isExecutable
            ? "\(targetName) 进入将令范围，\(preview.summary)。"
            : "\(preview.summary) · \(blockedReason ?? "暂不建议发动")。"

        return CommanderSynergyReport(
            id: "synergy-skill-\(unit.id)",
            faction: unit.faction,
            kind: .commanderSkill,
            unitID: unit.id,
            commanderUnitID: unit.id,
            targetUnitID: targetUnitID,
            targetCityID: targetCityID,
            targetPosition: targetPosition,
            supportingUnitIDs: supportingUnitIDs,
            beneficiaryUnitIDs: beneficiaryUnitIDs,
            recommendedOrder: formation.recommendedOrder,
            formationRole: formation.role,
            formationReadiness: formation.readiness,
            risk: risk,
            projectedDamage: nil,
            supportBonus: 0,
            flankingBonus: 0,
            commandBonus: 0,
            projectedRecoveredHealth: preview.projectedRecoveredHealth,
            projectedFortificationReduction: preview.projectedFortificationReduction,
            isExecutable: isExecutable,
            blockedReason: blockedReason,
            score: score,
            title: title,
            summary: summary,
            detail: detail,
            steps: steps
        )
    }

    private func commanderAttackSynergyReport(
        for unit: ArmyUnit,
        formation: LegionFormationReport
    ) -> CommanderSynergyReport? {
        guard unit.faction == activeFaction,
              !unit.hasActed else {
            return nil
        }

        let candidates = attackTargets(for: unit).compactMap { target -> (unit: ArmyUnit, preview: CombatPreview, score: Int)? in
            guard let preview = try? attackPreview(attackerID: unit.id, defenderID: target.id) else {
                return nil
            }

            let modifierScore = preview.supportBonus * 18 + preview.flankingBonus * 22 + preview.commandBonus * 24
            let score = preview.damage * 11 -
                preview.retaliation * 6 +
                modifierScore +
                (preview.defeatsDefender ? 180 : 0) +
                (target.generalName == nil ? 0 : 70)
            return (target, preview, score)
        }

        guard let best = candidates.sorted(by: { left, right in
            if left.score == right.score {
                return left.unit.id < right.unit.id
            }
            return left.score > right.score
        }).first else {
            return nil
        }

        let commanderUnitIDs = commanderSupportUnitIDs(for: unit)
        let adjacentSupportIDs = adjacentFriendlyUnitIDs(around: unit.position, faction: unit.faction, excluding: [unit.id])
        let flankingSupportIDs = adjacentFriendlyUnitIDs(around: best.unit.position, faction: unit.faction, excluding: [unit.id])
        let supportingUnitIDs = Array(Set(adjacentSupportIDs + flankingSupportIDs + commanderUnitIDs))
            .sorted()
        let targetName = battlefieldUnitName(unitID: best.unit.id, fallback: best.unit.kind.displayName)
        let risk = tacticalRisk(for: unit, preview: best.preview)
        let recommendedOrder: TacticalOrder = best.preview.defeatsDefender && unit.healthRatio >= 0.55 ? .assault : formation.recommendedOrder
        let modifierParts = commanderSynergyModifierParts(preview: best.preview)
        let modifierText = modifierParts.isEmpty ? "无额外修正" : modifierParts.joined(separator: " · ")
        let steps = commanderSynergySteps(
            unit: unit,
            role: .mainEffort,
            targetPosition: best.unit.position,
            recommendedOrder: recommendedOrder,
            summary: "攻击\(targetName)",
            detail: "预计伤害 \(best.preview.damage)，\(modifierText)",
            extraUnits: supportingUnitIDs.compactMap { self.unit(withID: $0) },
            extraRole: .support,
            extraDetail: "提供支援、包夹或指挥修正"
        )
        let score = 520 +
            CommanderSynergyKind.coordinatedAttack.priority * 110 +
            best.score +
            supportingUnitIDs.count * 24 +
            formation.readiness.priority * 20 -
            risk.priority * 18

        return CommanderSynergyReport(
            id: "synergy-attack-\(unit.id)-\(best.unit.id)",
            faction: unit.faction,
            kind: .coordinatedAttack,
            unitID: unit.id,
            commanderUnitID: commanderUnitIDs.first,
            targetUnitID: best.unit.id,
            targetCityID: nil,
            targetPosition: best.unit.position,
            supportingUnitIDs: supportingUnitIDs,
            beneficiaryUnitIDs: [],
            recommendedOrder: recommendedOrder,
            formationRole: formation.role,
            formationReadiness: formation.readiness,
            risk: risk,
            projectedDamage: best.preview.damage,
            supportBonus: best.preview.supportBonus,
            flankingBonus: best.preview.flankingBonus,
            commandBonus: best.preview.commandBonus,
            projectedRecoveredHealth: 0,
            projectedFortificationReduction: 0,
            isExecutable: true,
            blockedReason: nil,
            score: score,
            title: "合击：\(targetName)",
            summary: "预计伤害 \(best.preview.damage) · \(risk.displayName)",
            detail: "\(unit.kind.displayName)可在\(recommendedOrder.displayName)姿态压制目标，\(modifierText)。",
            steps: steps
        )
    }

    private func commanderRecommendationSynergyReport(
        for unit: ArmyUnit,
        formation: LegionFormationReport,
        recommendation: TacticalRecommendationReport
    ) -> CommanderSynergyReport {
        let kind = commanderSynergyKind(for: recommendation.kind)
        let targetName = battlefieldTargetName(
            unitID: recommendation.targetUnitID,
            cityID: recommendation.targetCityID,
            fallback: recommendation.targetPosition.description
        )
        let isExecutable = recommendation.kind == .hold ? false : (!unit.hasMoved || !unit.hasActed)
        let blockedReason = isExecutable ? nil : "本回合只能作为态势提示"
        let supportIDs: [String]
        if let targetUnitID = recommendation.targetUnitID,
           self.unit(withID: targetUnitID)?.faction == unit.faction {
            supportIDs = [targetUnitID]
        } else {
            supportIDs = []
        }
        let steps = commanderSynergySteps(
            unit: unit,
            role: kind == .recover ? .reserve : .mainEffort,
            targetPosition: recommendation.targetPosition,
            recommendedOrder: recommendation.recommendedOrder,
            summary: recommendation.kind.displayName,
            detail: recommendation.command,
            extraUnits: supportIDs.compactMap { self.unit(withID: $0) },
            extraRole: .beneficiary,
            extraDetail: "等待\(unit.kind.displayName)补线"
        )
        let score = 180 +
            kind.priority * 100 +
            recommendation.priority +
            recommendation.risk.priority * 25 +
            formation.readiness.priority * 18

        return CommanderSynergyReport(
            id: "synergy-\(kind.rawValue)-\(unit.id)-\(recommendation.targetUnitID ?? recommendation.targetCityID ?? "position")",
            faction: unit.faction,
            kind: kind,
            unitID: unit.id,
            commanderUnitID: unit.generalName == nil ? nil : unit.id,
            targetUnitID: recommendation.targetUnitID,
            targetCityID: recommendation.targetCityID,
            targetPosition: recommendation.targetPosition,
            supportingUnitIDs: supportIDs,
            beneficiaryUnitIDs: supportIDs,
            recommendedOrder: recommendation.recommendedOrder,
            formationRole: formation.role,
            formationReadiness: formation.readiness,
            risk: recommendation.risk,
            projectedDamage: recommendation.projectedDamage,
            supportBonus: 0,
            flankingBonus: 0,
            commandBonus: 0,
            projectedRecoveredHealth: 0,
            projectedFortificationReduction: 0,
            isExecutable: isExecutable,
            blockedReason: blockedReason,
            score: score,
            title: "\(kind.displayName)：\(targetName)",
            summary: "\(recommendation.risk.displayName) · \(recommendation.recommendedOrder.displayName)",
            detail: "\(recommendation.reason) \(recommendation.command)",
            steps: steps
        )
    }

    private func commanderSynergyKind(for recommendationKind: TacticalRecommendationKind) -> CommanderSynergyKind {
        switch recommendationKind {
        case .attack: return .coordinatedAttack
        case .reinforce: return .reinforce
        case .advance: return .advance
        case .hold, .recover: return .recover
        }
    }

    private func commanderSynergyRisk(for readiness: LegionFormationReadiness) -> TacticalRecommendationRisk {
        switch readiness {
        case .critical: return .critical
        case .strained: return .high
        case .engaged: return .guarded
        case .steady, .fresh: return .low
        }
    }

    private func commanderSynergySteps(
        unit: ArmyUnit,
        role: CommanderSynergyRole,
        targetPosition: Position,
        recommendedOrder: TacticalOrder,
        summary: String,
        detail: String,
        extraUnits: [ArmyUnit],
        extraRole: CommanderSynergyRole,
        extraDetail: String
    ) -> [CommanderSynergyStepReport] {
        var steps = [
            CommanderSynergyStepReport(
                unitID: unit.id,
                faction: unit.faction,
                role: role,
                position: unit.position,
                targetPosition: targetPosition,
                tacticalOrder: recommendedOrder,
                summary: summary,
                detail: detail
            )
        ]

        for extra in extraUnits where extra.id != unit.id {
            steps.append(
                CommanderSynergyStepReport(
                    unitID: extra.id,
                    faction: extra.faction,
                    role: extraRole,
                    position: extra.position,
                    targetPosition: targetPosition,
                    tacticalOrder: extra.resolvedTacticalOrder,
                    summary: extraRole.displayName,
                    detail: extraDetail
                )
            )
        }

        return steps
    }

    private func commanderSynergyModifierParts(preview: CombatPreview) -> [String] {
        [
            preview.supportBonus > 0 ? "支援 +\(preview.supportBonus)" : nil,
            preview.flankingBonus > 0 ? "包夹 +\(preview.flankingBonus)" : nil,
            preview.commandBonus > 0 ? "指挥 +\(preview.commandBonus)" : nil
        ].compactMap { $0 }
    }

    private func adjacentFriendlyUnitIDs(
        around position: Position,
        faction: Faction,
        excluding excludedIDs: Set<String>
    ) -> [String] {
        units
            .filter { unit in
                unit.faction == faction &&
                    !excludedIDs.contains(unit.id) &&
                    unit.position.hexDistance(to: position) <= 1
            }
            .map(\.id)
            .sorted()
    }

    private func commanderSupportUnitIDs(for unit: ArmyUnit) -> [String] {
        units
            .filter { commander in
                commander.faction == unit.faction &&
                    commander.generalName != nil &&
                    unit.position.hexDistance(to: commander.position) <= max(1, commander.resolvedGeneralTrait?.commandRange ?? 1)
            }
            .map(\.id)
            .sorted()
    }

    private func mapControlReport(
        at position: Position,
        for faction: Faction,
        pressure: FrontlinePressureReport?
    ) -> MapControlReport {
        let tile = tile(at: position)!
        let city = city(at: position)
        let occupant = unit(at: position)
        var friendlyInfluence = 0
        var enemyInfluence = 0
        var friendlyUnitIDs: [String] = []
        var enemyUnitIDs: [String] = []

        if let city,
           city.owner != .neutral {
            if city.owner == faction {
                friendlyInfluence += 22 + city.fortification
            } else if diplomaticStatus(between: faction, and: city.owner) == .war {
                enemyInfluence += 22 + city.fortification
            }
        }

        for unit in units where unit.faction != .neutral {
            let relation = mapControlRelation(of: unit.faction, to: faction)
            guard relation != .ignored else { continue }

            let influence = mapControlInfluence(from: unit, to: position)
            guard influence > 0 else { continue }

            if relation == .friendly {
                friendlyInfluence += influence
                if !friendlyUnitIDs.contains(unit.id) {
                    friendlyUnitIDs.append(unit.id)
                }
            } else {
                enemyInfluence += influence
                if !enemyUnitIDs.contains(unit.id) {
                    enemyUnitIDs.append(unit.id)
                }
            }
        }

        friendlyUnitIDs.sort()
        enemyUnitIDs.sort()

        let pressureScore = pressure?.pressureScore ?? max(0, enemyInfluence - friendlyInfluence)
        let controlState = mapControlState(friendlyInfluence: friendlyInfluence, enemyInfluence: enemyInfluence)
        let threatLevel = threatHeatLevel(
            friendlyInfluence: friendlyInfluence,
            enemyInfluence: enemyInfluence,
            pressure: pressure
        )
        let summary = "\(controlState.displayName) · \(threatLevel.displayName)"
        let detail = mapControlDetail(
            friendlyInfluence: friendlyInfluence,
            enemyInfluence: enemyInfluence,
            pressure: pressure,
            city: city,
            occupant: occupant
        )

        return MapControlReport(
            position: position,
            terrain: tile.terrain,
            perspectiveFaction: faction,
            cityID: city?.id,
            cityOwner: city?.owner,
            occupantUnitID: occupant?.id,
            occupantFaction: occupant?.faction,
            friendlyInfluence: friendlyInfluence,
            enemyInfluence: enemyInfluence,
            controlState: controlState,
            threatLevel: threatLevel,
            friendlyUnitIDs: friendlyUnitIDs,
            enemyUnitIDs: enemyUnitIDs,
            pressureScore: pressureScore,
            summary: summary,
            detail: detail
        )
    }

    private func threatHeatZoneReport(
        from report: MapControlReport,
        pressure: FrontlinePressureReport?
    ) -> ThreatHeatZoneReport {
        let sourceUnitIDs = Array(Set((pressure?.sourceUnitIDs ?? []) + report.enemyUnitIDs)).sorted()
        let positions = Set(
            [report.position] +
                report.position.neighbors(width: width, height: height) +
                sourceUnitIDs.compactMap { unit(withID: $0)?.position }
        )
            .sorted { left, right in
                if left.y == right.y { return left.x < right.x }
                return left.y < right.y
            }
        let cityIDs = positions.compactMap { city(at: $0)?.id }
        let attackIntentCount = pressure?.attackIntentCount ?? 0
        let captureIntentCount = pressure?.captureIntentCount ?? 0
        let projectedDamageTotal = pressure?.projectedDamageTotal ?? 0
        let score = report.pressureScore +
            report.enemyInfluence * 4 -
            report.friendlyInfluence * 2 +
            report.threatLevel.priority * 90 +
            attackIntentCount * 35 +
            captureIntentCount * 60
        let title = threatHeatTitle(for: report, pressure: pressure)
        let detail = threatHeatDetail(for: report, pressure: pressure)

        return ThreatHeatZoneReport(
            id: "heat-\(report.id)",
            perspectiveFaction: report.perspectiveFaction,
            center: report.position,
            positions: positions,
            controlState: report.controlState,
            threatLevel: report.threatLevel,
            friendlyInfluence: report.friendlyInfluence,
            enemyInfluence: report.enemyInfluence,
            sourceUnitIDs: sourceUnitIDs,
            cityIDs: cityIDs,
            attackIntentCount: attackIntentCount,
            captureIntentCount: captureIntentCount,
            projectedDamageTotal: projectedDamageTotal,
            score: max(1, score),
            title: title,
            detail: detail
        )
    }

    private enum MapControlRelation {
        case friendly
        case enemy
        case ignored
    }

    private func mapControlRelation(of faction: Faction, to perspective: Faction) -> MapControlRelation {
        if faction == perspective {
            return .friendly
        }

        guard faction != .neutral,
              perspective != .neutral,
              diplomaticStatus(between: perspective, and: faction) == .war else {
            return .ignored
        }

        return .enemy
    }

    private func mapControlInfluence(from unit: ArmyUnit, to position: Position) -> Int {
        var influence = 0
        let distance = unit.position.hexDistance(to: position)

        if unit.position == position {
            influence += 48
        }

        if distance <= unit.kind.range {
            influence += 24 + max(0, effectiveAttack(for: unit) / 4)
        } else if distance == unit.kind.range + 1 {
            influence += 8
        }

        let reachable = reachablePositions(for: unit)
        if reachable.contains(position) {
            influence += 14
        }

        if reachable.contains(where: { $0.hexDistance(to: position) <= unit.kind.range }) {
            influence += 10
        }

        return influence
    }

    private func mapControlState(
        friendlyInfluence: Int,
        enemyInfluence: Int
    ) -> MapControlState {
        if friendlyInfluence == 0 && enemyInfluence == 0 {
            return .neutral
        }

        if friendlyInfluence > 0 && enemyInfluence > 0 {
            if abs(friendlyInfluence - enemyInfluence) <= 18 {
                return .contested
            }
            return friendlyInfluence > enemyInfluence ? .friendlyControlled : .enemyControlled
        }

        return friendlyInfluence > 0 ? .friendlyControlled : .enemyControlled
    }

    private func threatHeatLevel(
        friendlyInfluence: Int,
        enemyInfluence: Int,
        pressure: FrontlinePressureReport?
    ) -> ThreatHeatLevel {
        let delta = enemyInfluence - friendlyInfluence

        if pressure?.level == .critical ||
            (pressure?.captureIntentCount ?? 0) > 0 ||
            delta >= 36 {
            return .critical
        }

        if pressure?.level == .threatened ||
            delta >= 18 {
            return .danger
        }

        if pressure?.level == .contested ||
            (friendlyInfluence > 0 && enemyInfluence > 0) {
            return .contested
        }

        if enemyInfluence > 0 {
            return .watched
        }

        return .quiet
    }

    private func frontlinePressureByPosition(against faction: Faction) -> [Position: FrontlinePressureReport] {
        var values: [Position: FrontlinePressureReport] = [:]
        for report in frontlinePressureReports(against: faction, perFactionLimit: 4, limit: 8) {
            let current = values[report.targetPosition]
            if current == nil || report.pressureScore > (current?.pressureScore ?? 0) {
                values[report.targetPosition] = report
            }
        }
        return values
    }

    private func mapControlDetail(
        friendlyInfluence: Int,
        enemyInfluence: Int,
        pressure: FrontlinePressureReport?,
        city: City?,
        occupant: ArmyUnit?
    ) -> String {
        var parts = [
            "友 \(friendlyInfluence)",
            "敌 \(enemyInfluence)"
        ]

        if let pressure {
            if pressure.captureIntentCount > 0 {
                parts.append("\(pressure.captureIntentCount) 路夺城")
            }
            if pressure.attackIntentCount > 0 {
                parts.append("\(pressure.attackIntentCount) 路攻击")
            }
            if pressure.projectedDamageTotal > 0 {
                parts.append("预计伤害 \(pressure.projectedDamageTotal)")
            }
        }

        if let city {
            parts.append("\(city.name) \(city.owner.displayName)")
        }

        if let occupant {
            parts.append("\(occupant.faction.displayName)\(occupant.kind.displayName)")
        }

        return parts.joined(separator: " · ")
    }

    private func threatHeatTitle(for report: MapControlReport, pressure: FrontlinePressureReport?) -> String {
        if let cityID = pressure?.targetKind == .city ? pressure?.targetID : nil,
           let city = city(withID: cityID) {
            return "\(city.name) \(report.threatLevel.displayName)"
        }

        if let unitID = pressure?.targetKind == .unit ? pressure?.targetID : nil,
           let unit = unit(withID: unitID) {
            return "\(unit.faction.displayName)\(unit.kind.displayName) \(report.threatLevel.displayName)"
        }

        return "\(report.position.description) \(report.threatLevel.displayName)"
    }

    private func threatHeatDetail(for report: MapControlReport, pressure: FrontlinePressureReport?) -> String {
        if let pressure {
            let source = pressure.sourceFactions.map(\.displayName).joined(separator: "、")
            let impact = pressure.captureIntentCount > 0
                ? "\(pressure.captureIntentCount) 路夺城"
                : "预计伤害 \(pressure.projectedDamageTotal)"
            return "\(source) \(pressure.intentCount) 路动向 · \(impact) · 控制差 \(report.enemyInfluence - report.friendlyInfluence)"
        }

        return "\(report.controlState.displayName) · 友 \(report.friendlyInfluence) / 敌 \(report.enemyInfluence)"
    }

    private func aiOperationalPlanKind(for intent: AIIntent) -> AIOperationalPlanKind {
        switch intent.kind {
        case .attack, .advanceAttack:
            return .focusedAttack
        case .captureCity:
            return .cityCapture
        case .useSkill:
            return .commanderSkill
        case .advance:
            return .advance
        case .defend:
            return .defend
        case .regroup:
            return .regroup
        }
    }

    private func aiOperationalTargetPosition(for intent: AIIntent, fallback: Position) -> Position {
        if let targetUnitID = intent.targetUnitID,
           let targetUnit = unit(withID: targetUnitID) {
            return targetUnit.position
        }

        if let targetCityID = intent.targetCityID,
           let targetCity = city(withID: targetCityID) {
            return targetCity.position
        }

        return intent.destination ?? fallback
    }

    private func aiPlanStepReport(
        for intent: AIIntent,
        unit: ArmyUnit,
        targetPosition: Position
    ) -> AIPlanStepReport {
        let formation = legionFormationReport(for: unit)
        let destination = intent.destination ?? unit.position
        let role: AIPlanCoordinationRole
        switch intent.kind {
        case .useSkill:
            role = .commander
        case .defend, .regroup:
            role = .reserve
        case .attack, .advanceAttack, .captureCity, .advance:
            role = .support
        }

        return AIPlanStepReport(
            unitID: intent.unitID,
            faction: intent.faction,
            intentKind: intent.kind,
            coordinationRole: role,
            origin: unit.position,
            destination: destination,
            targetPosition: targetPosition,
            targetUnitID: intent.targetUnitID,
            targetCityID: intent.targetCityID,
            tacticalOrder: intent.tacticalOrder,
            projectedDamage: intent.projectedDamage,
            threatScore: intent.threatScore,
            formationRole: formation.role,
            formationReadiness: formation.readiness,
            generalName: formation.generalName,
            skillSummary: intent.kind == .useSkill ? formation.skillSummary : nil,
            detail: aiPlanStepDetail(for: intent, unit: unit, formation: formation, targetPosition: targetPosition)
        )
    }

    private func aiPlanStepDetail(
        for intent: AIIntent,
        unit: ArmyUnit,
        formation: LegionFormationReport,
        targetPosition: Position
    ) -> String {
        let unitLabel = "\(unit.faction.displayName)\(unit.kind.displayName)"
        let target = battlefieldTargetName(
            unitID: intent.targetUnitID,
            cityID: intent.targetCityID,
            fallback: targetPosition.description
        )

        switch intent.kind {
        case .attack, .advanceAttack:
            return "\(unitLabel) 指向 \(target) · 预计伤害 \(intent.projectedDamage ?? 0)"
        case .captureCity:
            return "\(unitLabel) 试图夺取 \(target)"
        case .useSkill:
            let general = formation.generalName ?? "敌方将领"
            return "\(general) \(formation.skillSummary ?? "准备发动主动技能")"
        case .advance:
            return "\(unitLabel) 推进至 \(intent.destination?.description ?? targetPosition.description)"
        case .defend:
            return "\(unitLabel) 固守 \(target)"
        case .regroup:
            return "\(unitLabel) 整备恢复战力"
        }
    }

    private func aiOperationalPressure(
        for key: AIOperationalPlanKey,
        in reports: [FrontlinePressureReport]
    ) -> FrontlinePressureReport? {
        if let targetUnitID = key.targetUnitID,
           let report = reports.first(where: { $0.targetKind == .unit && $0.targetID == targetUnitID }) {
            return report
        }

        if let targetCityID = key.targetCityID,
           let report = reports.first(where: { $0.targetKind == .city && $0.targetID == targetCityID }) {
            return report
        }

        return reports.first { $0.targetPosition == key.targetPosition }
    }

    private func aiOperationalHeat(
        for targetPosition: Position,
        in reports: [ThreatHeatZoneReport]
    ) -> ThreatHeatZoneReport? {
        reports.first { $0.center == targetPosition } ??
            reports.first { $0.positions.contains(targetPosition) }
    }

    private func aiOperationalPlanReport(
        for key: AIOperationalPlanKey,
        steps rawSteps: [AIPlanStepReport],
        pressure: FrontlinePressureReport?,
        heat: ThreatHeatZoneReport?
    ) -> AIOperationalPlanReport {
        let steps = aiOperationalStepsWithRoles(rawSteps)
        let sourceUnitIDs = steps.map(\.unitID)
        let commanderUnitIDs = steps
            .filter { $0.coordinationRole == .commander }
            .map(\.unitID)
        let intentKinds = steps
            .map(\.intentKind)
            .reduce(into: [AIIntentKind]()) { unique, kind in
                guard !unique.contains(kind) else {
                    return
                }
                unique.append(kind)
            }
            .sorted { $0.rawValue < $1.rawValue }
        let projectedDamageTotal = steps.reduce(0) { partial, step in
            partial + (step.projectedDamage ?? 0)
        }
        let targetName = battlefieldTargetName(
            unitID: key.targetUnitID,
            cityID: key.targetCityID,
            fallback: key.targetPosition.description
        )
        let pressureScore = pressure?.pressureScore ?? 0
        let heatScore = (heat?.threatLevel.priority ?? 0) * 80
        let maxThreatScore = steps.map(\.threatScore).max() ?? 0
        let score = key.kind.priority * 200 +
            maxThreatScore +
            projectedDamageTotal * 2 +
            pressureScore +
            heatScore +
            commanderUnitIDs.count * 70 +
            steps.count * 25
        let pressureLabel = pressure?.level.displayName ?? "无集中压力"
        let heatLabel = heat?.threatLevel.displayName ?? "无热区"
        let impact = projectedDamageTotal > 0 ? "预计伤害 \(projectedDamageTotal)" : "\(steps.count) 步协同"
        let title = "\(key.faction.displayName)\(key.kind.displayName)：\(targetName)"
        let summary = "\(steps.count) 支 · \(pressureLabel) · \(heatLabel)"
        let detail = aiOperationalPlanDetail(
            kind: key.kind,
            targetName: targetName,
            impact: impact,
            steps: steps,
            commanders: commanderUnitIDs
        )

        return AIOperationalPlanReport(
            id: "\(key.faction.rawValue)-\(key.kind.rawValue)-\(key.targetPosition.x)-\(key.targetPosition.y)-\(key.targetUnitID ?? key.targetCityID ?? "position")",
            faction: key.faction,
            kind: key.kind,
            targetPosition: key.targetPosition,
            targetUnitID: key.targetUnitID,
            targetCityID: key.targetCityID,
            sourceUnitIDs: sourceUnitIDs,
            commanderUnitIDs: commanderUnitIDs,
            intentKinds: intentKinds,
            pressureLevel: pressure?.level,
            threatHeatLevel: heat?.threatLevel,
            projectedDamageTotal: projectedDamageTotal,
            score: score,
            title: title,
            summary: summary,
            detail: detail,
            steps: steps
        )
    }

    private func aiOperationalStepsWithRoles(_ steps: [AIPlanStepReport]) -> [AIPlanStepReport] {
        var hasMainEffort = false
        var assigned = steps
            .sorted { left, right in
                if left.threatScore == right.threatScore {
                    return left.unitID < right.unitID
                }
                return left.threatScore > right.threatScore
            }

        for index in assigned.indices {
            switch assigned[index].intentKind {
            case .useSkill:
                assigned[index].coordinationRole = .commander
            case .attack, .advanceAttack, .captureCity, .advance:
                assigned[index].coordinationRole = hasMainEffort ? .support : .mainEffort
                hasMainEffort = true
            case .defend, .regroup:
                assigned[index].coordinationRole = .reserve
            }
        }

        return assigned.sorted { left, right in
            if left.coordinationRole.priority == right.coordinationRole.priority {
                if left.threatScore == right.threatScore {
                    return left.unitID < right.unitID
                }
                return left.threatScore > right.threatScore
            }
            return left.coordinationRole.priority > right.coordinationRole.priority
        }
    }

    private func aiOperationalPlanDetail(
        kind: AIOperationalPlanKind,
        targetName: String,
        impact: String,
        steps: [AIPlanStepReport],
        commanders: [String]
    ) -> String {
        let main = steps.first { $0.coordinationRole == .mainEffort }
        let mainLabel = main.flatMap { unit(withID: $0.unitID) }.map { "\($0.faction.displayName)\($0.kind.displayName)" } ?? "敌军"
        let commanderLabel = commanders
            .compactMap { unit(withID: $0)?.generalName }
            .joined(separator: "、")
        let commanderText = commanderLabel.isEmpty ? "" : " · 将领 \(commanderLabel)"
        return "\(kind.displayName) \(targetName) · \(mainLabel) 主导 · \(impact)\(commanderText)"
    }

    private func battlefieldPressureFocusReports(for faction: Faction) -> [BattlefieldFocusReport] {
        frontlinePressureReports(against: faction, perFactionLimit: 4, limit: 4).map { pressure in
            let severity = battlefieldSeverity(for: pressure.level)
            let kind: BattlefieldFocusKind = pressure.level == .critical || pressure.level == .threatened ? .defense : .reinforce
            let targetUnitID = pressure.targetKind == .unit ? pressure.targetID : nil
            let targetCityID = pressure.targetKind == .city ? pressure.targetID : nil
            let impact = pressure.captureIntentCount > 0
                ? "\(pressure.captureIntentCount) 路夺城"
                : "预计伤害 \(pressure.projectedDamageTotal)"
            let targetName = battlefieldTargetName(unitID: targetUnitID, cityID: targetCityID, fallback: pressure.targetKind.displayName)
            let score = 800 + pressure.pressureScore + severity.priority * 90 + pressure.attackIntentCount * 25 + pressure.captureIntentCount * 40

            return BattlefieldFocusReport(
                id: "pressure-\(pressure.id)",
                faction: faction,
                kind: kind,
                severity: severity,
                position: pressure.targetPosition,
                unitID: targetUnitID,
                targetUnitID: targetUnitID,
                targetCityID: targetCityID,
                relatedUnitIDs: pressure.sourceUnitIDs,
                recommendedOrder: .defensive,
                score: score,
                title: "\(targetName) \(pressure.level.displayName)",
                summary: "\(kind.displayName) · \(impact)",
                detail: "\(pressure.sourceFactions.map(\.displayName).joined(separator: "、")) \(pressure.intentCount) 路动向，\(impact)，优先稳住 \(pressure.targetPosition.description)。"
            )
        }
    }

    private func battlefieldTacticalFocus(for recommendation: TacticalRecommendationReport) -> BattlefieldFocusReport? {
        let kind: BattlefieldFocusKind
        switch recommendation.kind {
        case .attack:
            kind = .attackOpportunity
        case .reinforce:
            kind = .reinforce
        case .advance:
            kind = .advance
        case .hold:
            guard recommendation.risk != .low else { return nil }
            kind = .defense
        case .recover:
            kind = .recover
        }

        let severity = battlefieldSeverity(for: recommendation.risk)
        let targetName = battlefieldTargetName(
            unitID: recommendation.targetUnitID,
            cityID: recommendation.targetCityID,
            fallback: recommendation.targetPosition.description
        )
        let score = 420 + recommendation.priority + severity.priority * 55
        let relatedUnitIDs = [recommendation.unitID, recommendation.targetUnitID].compactMap { $0 }

        return BattlefieldFocusReport(
            id: "tactical-\(recommendation.id)-\(recommendation.kind.rawValue)",
            faction: recommendation.faction,
            kind: kind,
            severity: severity,
            position: recommendation.targetPosition,
            unitID: recommendation.unitID,
            targetUnitID: recommendation.targetUnitID,
            targetCityID: recommendation.targetCityID,
            relatedUnitIDs: relatedUnitIDs,
            recommendedOrder: recommendation.recommendedOrder,
            score: score,
            title: "\(kind.displayName)：\(targetName)",
            summary: "\(recommendation.kind.displayName) · \(recommendation.risk.displayName)",
            detail: "\(recommendation.reason) \(recommendation.command)"
        )
    }

    private func battlefieldGeneralOpportunityFocus(for formation: LegionFormationReport) -> BattlefieldFocusReport? {
        guard formation.hasGeneral,
              formation.skillReady else {
            return nil
        }

        let severity: BattlefieldFocusSeverity = formation.readiness == .critical ? .critical : .urgent
        let generalName = formation.generalName ?? "将领"
        let skillName = formation.generalTrait?.skillName ?? "主动技能"
        let score = 760 + severity.priority * 80 + max(0, 100 - formation.formationIntegrityScore) + formation.nearbyEnemyCount * 35

        return BattlefieldFocusReport(
            id: "general-\(formation.unitID)",
            faction: formation.faction,
            kind: .generalOpportunity,
            severity: severity,
            position: formation.position,
            unitID: formation.unitID,
            targetUnitID: nil,
            targetCityID: nil,
            relatedUnitIDs: [formation.unitID],
            recommendedOrder: formation.recommendedOrder,
            score: score,
            title: "\(generalName) 可发动\(skillName)",
            summary: "将领机会 · \(formation.readiness.displayName)",
            detail: formation.skillSummary ?? formation.commandSuggestion
        )
    }

    private func battlefieldRecoveryFocus(for formation: LegionFormationReport) -> BattlefieldFocusReport? {
        guard formation.readiness == .critical || formation.readiness == .strained else {
            return nil
        }

        let severity = battlefieldSeverity(for: formation.readiness)
        let unitName = battlefieldUnitName(unitID: formation.unitID, fallback: formation.kind.displayName)
        let score = 500 + severity.priority * 90 + max(0, 100 - formation.formationIntegrityScore) + formation.nearbyEnemyCount * 20

        return BattlefieldFocusReport(
            id: "formation-\(formation.unitID)-recover",
            faction: formation.faction,
            kind: .recover,
            severity: severity,
            position: formation.position,
            unitID: formation.unitID,
            targetUnitID: formation.unitID,
            targetCityID: nil,
            relatedUnitIDs: [formation.unitID],
            recommendedOrder: formation.recommendedOrder,
            score: score,
            title: "\(unitName) 需要整编",
            summary: "整编 · \(formation.readiness.displayName)",
            detail: formation.commandSuggestion
        )
    }

    private func battlefieldSeverity(for level: FrontlinePressureLevel) -> BattlefieldFocusSeverity {
        switch level {
        case .critical: return .critical
        case .threatened: return .urgent
        case .contested: return .important
        case .watch: return .watch
        }
    }

    private func battlefieldSeverity(for risk: TacticalRecommendationRisk) -> BattlefieldFocusSeverity {
        switch risk {
        case .critical: return .critical
        case .high: return .urgent
        case .guarded: return .important
        case .low: return .watch
        }
    }

    private func battlefieldSeverity(for readiness: LegionFormationReadiness) -> BattlefieldFocusSeverity {
        switch readiness {
        case .critical: return .critical
        case .strained: return .urgent
        case .engaged: return .important
        case .steady, .fresh: return .watch
        }
    }

    private func battlefieldTargetName(unitID: String?, cityID: String?, fallback: String) -> String {
        if let unitID {
            return battlefieldUnitName(unitID: unitID, fallback: fallback)
        }

        if let cityID,
           let city = city(withID: cityID) {
            return city.name
        }

        return fallback
    }

    private func battlefieldUnitName(unitID: String, fallback: String) -> String {
        guard let unit = unit(withID: unitID) else {
            return fallback
        }

        return "\(unit.faction.displayName)\(unit.kind.displayName)"
    }

    private func tacticalReachableDestinations(for unit: ArmyUnit) -> Set<Position> {
        guard unit.faction == activeFaction,
              !unit.hasMoved else {
            return []
        }

        return reachablePositions(for: unit)
    }

    private func tacticalBestDestination(
        from destinations: Set<Position>,
        toward target: Position,
        for _: ArmyUnit
    ) -> Position? {
        destinations.sorted { left, right in
            let leftDistance = left.hexDistance(to: target)
            let rightDistance = right.hexDistance(to: target)
            if leftDistance != rightDistance {
                return leftDistance < rightDistance
            }

            let leftDefense = tile(at: left)?.terrain.defenseBonus ?? 0
            let rightDefense = tile(at: right)?.terrain.defenseBonus ?? 0
            if leftDefense != rightDefense {
                return leftDefense > rightDefense
            }

            if left.y != right.y {
                return left.y < right.y
            }
            return left.x < right.x
        }.first
    }

    private func tacticalRisk(for unit: ArmyUnit, preview: CombatPreview) -> TacticalRecommendationRisk {
        if preview.attackerFalls || preview.attackerRemainingHealth <= max(1, unit.kind.maxHealth / 5) {
            return .critical
        }

        if preview.retaliation >= max(1, unit.health / 2) {
            return .high
        }

        if preview.retaliation > 0 || unit.healthRatio <= 0.55 {
            return .guarded
        }

        return .low
    }

    private func tacticalPath(from origin: Position, to destination: Position, for unit: ArmyUnit) -> [Position]? {
        guard origin != destination else { return [origin] }

        let movementLimit = effectiveMovement(for: unit)
        var bestCost: [Position: Int] = [origin: 0]
        var previous: [Position: Position] = [:]
        var frontier = [origin]

        while !frontier.isEmpty {
            let currentIndex = frontier.indices.min { leftIndex, rightIndex in
                let left = frontier[leftIndex]
                let right = frontier[rightIndex]
                let leftCost = bestCost[left] ?? Int.max
                let rightCost = bestCost[right] ?? Int.max
                if leftCost != rightCost { return leftCost < rightCost }

                let leftDistance = left.hexDistance(to: destination)
                let rightDistance = right.hexDistance(to: destination)
                if leftDistance != rightDistance { return leftDistance < rightDistance }

                if left.y != right.y { return left.y < right.y }
                return left.x < right.x
            } ?? frontier.startIndex
            let current = frontier.remove(at: currentIndex)
            if current == destination {
                return tacticalReconstructPath(to: destination, from: previous, origin: origin)
            }

            let currentCost = bestCost[current] ?? 0
            for neighbor in current.neighbors(width: width, height: height) {
                guard let tile = tile(at: neighbor),
                      unit.kind.canEnter(tile.terrain),
                      self.unit(at: neighbor) == nil || neighbor == destination else {
                    continue
                }

                let nextCost = currentCost + tile.terrain.movementCost
                guard nextCost <= movementLimit else { continue }

                if nextCost < (bestCost[neighbor] ?? Int.max) {
                    bestCost[neighbor] = nextCost
                    previous[neighbor] = current
                    if !frontier.contains(neighbor) {
                        frontier.append(neighbor)
                    }
                }
            }
        }

        return nil
    }

    private func tacticalReconstructPath(
        to destination: Position,
        from previous: [Position: Position],
        origin: Position
    ) -> [Position]? {
        var path = [destination]
        var current = destination

        while current != origin {
            guard let step = previous[current] else { return nil }
            current = step
            path.append(current)
        }

        return path.reversed()
    }

    private func tacticalFallbackPath(from origin: Position, to destination: Position) -> [Position] {
        origin == destination ? [origin] : [origin, destination]
    }

    private func legionFormationReport(for unit: ArmyUnit) -> LegionFormationReport {
        let adjacentAllies = nearbyAlliedUnits(for: unit, range: 1)
        let nearbyAllies = nearbyAlliedUnits(for: unit, range: 2)
        let nearbyEnemies = nearbyEnemyUnits(for: unit, range: 2)
        let nearbyEnemyFactionCount = Set(nearbyEnemies.map(\.faction)).count
        let warMerit = warMeritStatus(for: unit)
        let skillPreview = unit.generalName == nil ? nil : generalSkillPreview(for: unit)
        let role = legionFormationRole(
            for: unit,
            adjacentAllyCount: adjacentAllies.count,
            nearbyAllyCount: nearbyAllies.count,
            nearbyEnemyCount: nearbyEnemies.count
        )
        let integrityScore = legionFormationIntegrityScore(
            for: unit,
            adjacentAllyCount: adjacentAllies.count,
            nearbyAllyCount: nearbyAllies.count,
            nearbyEnemyCount: nearbyEnemies.count
        )
        let readiness = legionFormationReadiness(
            for: unit,
            integrityScore: integrityScore,
            nearbyEnemyCount: nearbyEnemies.count
        )
        let recommendedOrder = recommendedFormationOrder(
            for: unit,
            role: role,
            readiness: readiness,
            adjacentAllyCount: adjacentAllies.count,
            nearbyEnemyCount: nearbyEnemies.count,
            skillPreview: skillPreview
        )
        let commandSuggestion = legionFormationSuggestion(
            for: unit,
            role: role,
            readiness: readiness,
            recommendedOrder: recommendedOrder,
            adjacentAllyCount: adjacentAllies.count,
            nearbyEnemyCount: nearbyEnemies.count,
            skillPreview: skillPreview
        )
        let detail = [
            "攻 \(effectiveAttack(for: unit))",
            "防 \(effectiveDefense(for: unit))",
            "移 \(effectiveMovement(for: unit))",
            "友军 \(adjacentAllies.count)/\(nearbyAllies.count)",
            "近敌 \(nearbyEnemies.count)",
            "完整度 \(integrityScore)"
        ].joined(separator: " · ")

        return LegionFormationReport(
            unitID: unit.id,
            faction: unit.faction,
            kind: unit.kind,
            position: unit.position,
            role: role,
            readiness: readiness,
            health: unit.health,
            maxHealth: unit.kind.maxHealth,
            experience: unit.experience,
            rankName: warMerit.rankName,
            hasGeneral: unit.generalName != nil,
            generalName: unit.generalName,
            generalTrait: unit.resolvedGeneralTrait,
            tacticalOrder: unit.resolvedTacticalOrder,
            recommendedOrder: recommendedOrder,
            attack: effectiveAttack(for: unit),
            defense: effectiveDefense(for: unit),
            movement: effectiveMovement(for: unit),
            adjacentAllyCount: adjacentAllies.count,
            nearbyAllyCount: nearbyAllies.count,
            nearbyEnemyCount: nearbyEnemies.count,
            nearbyEnemyFactionCount: nearbyEnemyFactionCount,
            skillReady: isFormationSkillUseful(skillPreview),
            skillSummary: skillPreview?.summary,
            formationIntegrityScore: integrityScore,
            commandSuggestion: commandSuggestion,
            detail: detail
        )
    }

    private func nearbyAlliedUnits(for unit: ArmyUnit, range: Int) -> [ArmyUnit] {
        units
            .filter { ally in
                ally.id != unit.id &&
                    ally.faction == unit.faction &&
                    unit.position.hexDistance(to: ally.position) <= range
            }
            .sorted { left, right in
                if left.position.hexDistance(to: unit.position) == right.position.hexDistance(to: unit.position) {
                    return left.id < right.id
                }
                return left.position.hexDistance(to: unit.position) < right.position.hexDistance(to: unit.position)
            }
    }

    private func nearbyEnemyUnits(for unit: ArmyUnit, range: Int) -> [ArmyUnit] {
        units
            .filter { enemy in
                enemy.faction != unit.faction &&
                    enemy.faction != .neutral &&
                    diplomaticStatus(between: unit.faction, and: enemy.faction) == .war &&
                    unit.position.hexDistance(to: enemy.position) <= range
            }
            .sorted { left, right in
                if left.position.hexDistance(to: unit.position) == right.position.hexDistance(to: unit.position) {
                    return left.id < right.id
                }
                return left.position.hexDistance(to: unit.position) < right.position.hexDistance(to: unit.position)
            }
    }

    private func legionFormationRole(
        for unit: ArmyUnit,
        adjacentAllyCount: Int,
        nearbyAllyCount: Int,
        nearbyEnemyCount: Int
    ) -> LegionFormationRole {
        if unit.kind == .navy {
            return .fleet
        }

        if unit.resolvedGeneralTrait == .siegeEngineer {
            return .siege
        }

        if unit.kind == .archer || unit.resolvedGeneralTrait == .quartermaster {
            return .support
        }

        if unit.generalName != nil && nearbyAllyCount > 0 {
            return .command
        }

        if nearbyEnemyCount > 0 && unit.healthRatio >= 0.55 {
            return .vanguard
        }

        if adjacentAllyCount == 0 && nearbyEnemyCount == 0 {
            return .reserve
        }

        return .line
    }

    private func legionFormationIntegrityScore(
        for unit: ArmyUnit,
        adjacentAllyCount: Int,
        nearbyAllyCount: Int,
        nearbyEnemyCount: Int
    ) -> Int {
        let healthScore = Int((unit.healthRatio * 55).rounded())
        let adjacentSupportScore = min(16, adjacentAllyCount * 8)
        let depthSupportScore = min(10, max(0, nearbyAllyCount - adjacentAllyCount) * 5)
        let commanderScore = unit.generalName == nil ? 0 : 10
        let actionScore = (unit.hasMoved ? 0 : 4) + (unit.hasActed ? 0 : 5)
        let postureScore = unit.resolvedTacticalOrder == .defensive && nearbyEnemyCount > 0 ? 6 : 0
        let enemyPenalty = min(28, nearbyEnemyCount * 9)
        return max(0, min(100, healthScore + adjacentSupportScore + depthSupportScore + commanderScore + actionScore + postureScore - enemyPenalty))
    }

    private func legionFormationReadiness(
        for unit: ArmyUnit,
        integrityScore: Int,
        nearbyEnemyCount: Int
    ) -> LegionFormationReadiness {
        if unit.healthRatio <= 0.30 ||
            (integrityScore < 35 && nearbyEnemyCount > 0) {
            return .critical
        }

        if unit.healthRatio <= 0.55 ||
            integrityScore < 50 {
            return .strained
        }

        if nearbyEnemyCount > 0 ||
            unit.hasMoved ||
            unit.hasActed {
            return .engaged
        }

        if integrityScore >= 75 {
            return .fresh
        }

        return .steady
    }

    private func recommendedFormationOrder(
        for unit: ArmyUnit,
        role: LegionFormationRole,
        readiness: LegionFormationReadiness,
        adjacentAllyCount: Int,
        nearbyEnemyCount: Int,
        skillPreview: GeneralSkillPreview?
    ) -> TacticalOrder {
        if isFormationSkillUseful(skillPreview) {
            return unit.resolvedTacticalOrder
        }

        if readiness == .critical ||
            readiness == .strained ||
            nearbyEnemyCount > adjacentAllyCount + 1 {
            return .defensive
        }

        if nearbyEnemyCount == 0 && !unit.hasMoved {
            return .forcedMarch
        }

        if role == .vanguard && unit.healthRatio >= 0.70 {
            return .assault
        }

        return .balanced
    }

    private func legionFormationSuggestion(
        for unit: ArmyUnit,
        role: LegionFormationRole,
        readiness: LegionFormationReadiness,
        recommendedOrder: TacticalOrder,
        adjacentAllyCount: Int,
        nearbyEnemyCount: Int,
        skillPreview: GeneralSkillPreview?
    ) -> String {
        if isFormationSkillUseful(skillPreview),
           let skillPreview = skillPreview,
           let trait = unit.resolvedGeneralTrait {
            return "优先发动\(trait.skillName)：\(skillPreview.summary)"
        }

        if readiness == .critical {
            return "危急：切换坚守并靠拢友军或城市补给。"
        }

        if readiness == .strained {
            return "吃紧：建议\(TacticalOrder.defensive.displayName)，等待支援后再接战。"
        }

        if nearbyEnemyCount > 0 && adjacentAllyCount == 0 {
            return "孤军接敌：先补齐相邻友军支援。"
        }

        if recommendedOrder == .assault {
            return "战线完整：可转突击压制近敌。"
        }

        if recommendedOrder == .forcedMarch {
            return "暂无近敌：可行军补线或抢占道路城市。"
        }

        if role == .support {
            return "保持二线支援，覆盖前排军团。"
        }

        if role == .command {
            return "维持指挥圈，保护将领并覆盖友军。"
        }

        return "保持战列，等待更明确目标。"
    }

    private func isFormationSkillUseful(_ preview: GeneralSkillPreview?) -> Bool {
        guard let preview,
              preview.isExecutable else {
            return false
        }

        return preview.projectedRecoveredHealth > 0 ||
            preview.projectedFortificationReduction > 0
    }

    private func legionFormationPriority(for report: LegionFormationReport) -> Int {
        report.readiness.priority * 1_000 +
            report.nearbyEnemyCount * 80 +
            (report.hasGeneral ? 60 : 0) +
            report.experience * 8 +
            max(0, 100 - report.formationIntegrityScore)
    }

    public func attackTargets(for unitID: String) -> [ArmyUnit] {
        guard let unit = unit(withID: unitID),
              unit.faction == activeFaction,
              !unit.hasActed else {
            return []
        }

        return attackTargets(for: unit)
    }

    private func attackTargets(for unit: ArmyUnit) -> [ArmyUnit] {
        guard unit.faction == activeFaction,
              !unit.hasActed else {
            return []
        }

        return units.filter { target in
            target.faction != unit.faction &&
                target.faction != .neutral &&
                diplomaticStatus(between: unit.faction, and: target.faction) == .war &&
                unit.position.hexDistance(to: target.position) <= unit.kind.range
        }
    }

    public func attackPreview(attackerID: String, defenderID: String) throws -> CombatPreview {
        guard let attacker = unit(withID: attackerID),
              let defender = unit(withID: defenderID) else {
            throw GameRuleError.missingEntity
        }

        guard attacker.faction == activeFaction else {
            throw GameRuleError.notActiveFaction
        }

        guard !attacker.hasActed else {
            throw GameRuleError.unitAlreadyActed
        }

        guard attacker.faction != defender.faction,
              attacker.position.hexDistance(to: defender.position) <= attacker.kind.range else {
            throw GameRuleError.invalidTarget
        }

        guard diplomaticStatus(between: attacker.faction, and: defender.faction) == .war else {
            throw GameRuleError.protectedByTreaty
        }

        let modifiers = combatModifiers(attacker: attacker, defender: defender)
        let damage = estimatedDamage(from: attacker, to: defender, modifiers: modifiers)
        let defenderRemainingHealth = max(0, defender.health - damage)
        let defeatsDefender = defenderRemainingHealth <= 0
        let retaliation = defeatsDefender || defender.position.hexDistance(to: attacker.position) > defender.kind.range
            ? 0
            : retaliationDamage(from: defender, to: attacker)
        let attackerRemainingHealth = max(0, attacker.health - retaliation)

        return CombatPreview(
            attackerID: attackerID,
            defenderID: defenderID,
            damage: damage,
            retaliation: retaliation,
            supportBonus: modifiers.supportBonus,
            flankingBonus: modifiers.flankingBonus,
            commandBonus: modifiers.commandBonus,
            defenderSupportBonus: modifiers.defenderSupportBonus,
            defenderRemainingHealth: defenderRemainingHealth,
            attackerRemainingHealth: attackerRemainingHealth,
            defeatsDefender: defeatsDefender,
            attackerFalls: attackerRemainingHealth <= 0
        )
    }

    public func nextReadyUnit(for faction: Faction) -> ArmyUnit? {
        units
            .filter { $0.faction == faction && (!$0.hasMoved || !$0.hasActed) }
            .sorted { left, right in
                if left.position.y == right.position.y {
                    return left.position.x < right.position.x
                }
                return left.position.y < right.position.y
            }
            .first
    }

    public func generalSkillPreview(unitID: String) throws -> GeneralSkillPreview {
        guard let commander = unit(withID: unitID) else {
            throw GameRuleError.missingEntity
        }

        guard commander.generalName != nil,
              commander.resolvedGeneralTrait != nil else {
            throw GameRuleError.generalSkillUnavailable
        }

        return generalSkillPreview(for: commander)
    }

    public func aiIntents(for faction: Faction, limit: Int = 4) -> [AIIntent] {
        guard faction != .neutral else {
            return []
        }

        return aiPlanningForecast(for: faction).aiIntentReports(for: faction, limit: limit)
    }

    private func aiPlanningForecast(for faction: Faction) -> GameState {
        var forecast = self
        forecast.activeFaction = faction
        forecast.refreshFactionForNewTurn(faction)
        return forecast
    }

    private func aiIntentReports(for faction: Faction, limit: Int) -> [AIIntent] {
        return units
            .filter { $0.faction == faction }
            .compactMap { aiIntent(for: $0) }
            .sorted { left, right in
                if left.threatScore == right.threatScore {
                    return left.unitID < right.unitID
                }
                return left.threatScore > right.threatScore
            }
            .prefix(max(0, limit))
            .map { $0 }
    }

    public func frontlinePressureReports(
        against defendingFaction: Faction = .rome,
        perFactionLimit: Int = 4,
        limit: Int = 6
    ) -> [FrontlinePressureReport] {
        guard defendingFaction != .neutral,
              perFactionLimit > 0,
              limit > 0 else {
            return []
        }

        var accumulators: [FrontlinePressureTargetKey: FrontlinePressureAccumulator] = [:]

        for faction in Faction.turnOrder where faction != defendingFaction && faction != .neutral {
            guard diplomaticStatus(between: defendingFaction, and: faction) == .war else {
                continue
            }

            for intent in aiIntents(for: faction, limit: perFactionLimit) {
                guard let target = frontlinePressureTarget(for: intent, against: defendingFaction) else {
                    continue
                }

                var accumulator = accumulators[target.key] ?? FrontlinePressureAccumulator(target: target)
                accumulator.add(intent)
                accumulators[target.key] = accumulator
            }
        }

        return accumulators.values
            .map(\.report)
            .sorted { left, right in
                if left.pressureScore == right.pressureScore {
                    return left.id < right.id
                }
                return left.pressureScore > right.pressureScore
            }
            .prefix(limit)
            .map { $0 }
    }

    private func frontlinePressureTarget(for intent: AIIntent, against defendingFaction: Faction) -> FrontlinePressureTarget? {
        if let targetUnitID = intent.targetUnitID,
           let targetUnit = unit(withID: targetUnitID),
           targetUnit.faction == defendingFaction {
            return FrontlinePressureTarget(
                key: FrontlinePressureTargetKey(kind: .unit, id: targetUnit.id),
                faction: targetUnit.faction,
                position: targetUnit.position,
                health: targetUnit.health
            )
        }

        if let targetCityID = intent.targetCityID,
           let targetCity = city(withID: targetCityID),
           targetCity.owner == defendingFaction {
            return FrontlinePressureTarget(
                key: FrontlinePressureTargetKey(kind: .city, id: targetCity.id),
                faction: targetCity.owner,
                position: targetCity.position,
                health: nil
            )
        }

        return nil
    }

    public mutating func moveUnit(id unitID: String, to destination: Position) throws -> [String] {
        try ensureCampaignCanContinue()

        guard let index = units.firstIndex(where: { $0.id == unitID }) else {
            throw GameRuleError.missingEntity
        }

        guard units[index].faction == activeFaction else {
            throw GameRuleError.notActiveFaction
        }

        guard !units[index].hasMoved else {
            throw GameRuleError.unitAlreadyMoved
        }

        guard reachablePositions(for: unitID).contains(destination) else {
            throw GameRuleError.invalidDestination
        }

        guard unit(at: destination) == nil else {
            throw GameRuleError.occupiedTile
        }

        units[index].position = destination
        units[index].hasMoved = true

        var messages = ["\(units[index].faction.displayName)\(units[index].kind.displayName)移动至 \(destination)。"]
        messages.append(contentsOf: captureCityIfPossible(at: destination, by: units[index].faction))
        messages.append(contentsOf: evaluateCampaignProgress())
        eventLog.append(contentsOf: messages)
        return messages
    }

    public mutating func attack(attackerID: String, defenderID: String) throws -> [String] {
        try ensureCampaignCanContinue()

        guard let attacker = unit(withID: attackerID),
              let defender = unit(withID: defenderID) else {
            throw GameRuleError.missingEntity
        }

        guard attacker.faction == activeFaction else {
            throw GameRuleError.notActiveFaction
        }

        guard !attacker.hasActed else {
            throw GameRuleError.unitAlreadyActed
        }

        guard attacker.faction != defender.faction,
              attacker.position.hexDistance(to: defender.position) <= attacker.kind.range else {
            throw GameRuleError.invalidTarget
        }

        guard diplomaticStatus(between: attacker.faction, and: defender.faction) == .war else {
            throw GameRuleError.protectedByTreaty
        }

        let preview = try attackPreview(attackerID: attackerID, defenderID: defenderID)
        let damage = preview.damage

        guard let attackerIndex = units.firstIndex(where: { $0.id == attackerID }),
              let defenderIndex = units.firstIndex(where: { $0.id == defenderID }) else {
            throw GameRuleError.missingEntity
        }

        units[attackerIndex].hasActed = true
        units[attackerIndex].hasMoved = true
        units[defenderIndex].health -= damage

        var messages = ["\(attacker.faction.displayName)\(attacker.kind.displayName)造成 \(damage) 点伤害。"]

        if let updatedDefender = unit(withID: defenderID), updatedDefender.health <= 0 {
            units.removeAll { $0.id == defenderID }
            messages.append("\(defender.faction.displayName)\(defender.kind.displayName)被击溃。")
            messages.append(contentsOf: evaluateCampaignProgress())
            eventLog.append(contentsOf: messages)
            return messages
        }

        if let updatedDefender = unit(withID: defenderID),
           updatedDefender.position.hexDistance(to: attacker.position) <= updatedDefender.kind.range,
           let updatedAttackerIndex = units.firstIndex(where: { $0.id == attackerID }) {
            let retaliation = preview.retaliation
            units[updatedAttackerIndex].health -= retaliation
            messages.append("\(updatedDefender.faction.displayName)\(updatedDefender.kind.displayName)反击 \(retaliation) 点。")

            if units[updatedAttackerIndex].health <= 0 {
                units.remove(at: updatedAttackerIndex)
                messages.append("\(attacker.faction.displayName)\(attacker.kind.displayName)被反击击溃。")
            }
        }

        messages.append(contentsOf: evaluateCampaignProgress())
        eventLog.append(contentsOf: messages)
        return messages
    }

    public mutating func developCity(id cityID: String) throws -> [String] {
        try ensureCampaignCanContinue()

        guard let cityIndex = cities.firstIndex(where: { $0.id == cityID }) else {
            throw GameRuleError.missingEntity
        }

        let preview = try cityDevelopmentPreview(id: cityID)
        guard preview.canDevelop else {
            throw preview.blockingError ?? GameRuleError.invalidTarget
        }

        var pool = resources[activeFaction] ?? .zero
        try pool.spend(preview.cost)
        resources[activeFaction] = pool

        cities[cityIndex].production.add(preview.productionIncrease)
        cities[cityIndex].fortification += preview.fortificationIncrease

        let messages = ["\(cities[cityIndex].name)完成扩建，产出与城防提升。"]
        eventLog.append(contentsOf: messages)
        return messages
    }

    public mutating func trainUnit(id unitID: String) throws -> [String] {
        try ensureCampaignCanContinue()

        guard let index = units.firstIndex(where: { $0.id == unitID }) else {
            throw GameRuleError.missingEntity
        }

        guard units[index].faction == activeFaction else {
            throw GameRuleError.notActiveFaction
        }

        let cost = EmpireResources(gold: 35, grain: 20, iron: 10, science: 0, prestige: 1)
        var pool = resources[activeFaction] ?? .zero
        try pool.spend(cost)
        resources[activeFaction] = pool

        units[index].experience += 1
        units[index].health = min(units[index].kind.maxHealth, units[index].health + 18)
        units[index].hasActed = true

        let messages = ["\(units[index].kind.displayName)完成训练，经验提升。"]
        eventLog.append(contentsOf: messages)
        return messages
    }

    public mutating func skipUnit(id unitID: String) throws -> [String] {
        try ensureCampaignCanContinue()

        guard let index = units.firstIndex(where: { $0.id == unitID }) else {
            throw GameRuleError.missingEntity
        }

        guard units[index].faction == activeFaction else {
            throw GameRuleError.notActiveFaction
        }

        units[index].hasMoved = true
        units[index].hasActed = true

        let messages = ["\(units[index].faction.displayName)\(units[index].kind.displayName)原地待机。"]
        eventLog.append(contentsOf: messages)
        return messages
    }

    public mutating func setTacticalOrder(unitID: String, order: TacticalOrder) throws -> [String] {
        try ensureCampaignCanContinue()

        guard let index = units.firstIndex(where: { $0.id == unitID }) else {
            throw GameRuleError.missingEntity
        }

        guard units[index].faction == activeFaction else {
            throw GameRuleError.notActiveFaction
        }

        guard units[index].resolvedTacticalOrder != order else {
            return []
        }

        guard !units[index].hasMoved, !units[index].hasActed else {
            throw GameRuleError.unitAlreadyMoved
        }

        units[index].tacticalOrder = order == .balanced ? nil : order
        let messages = ["\(units[index].faction.displayName)\(units[index].kind.displayName)改为\(order.displayName)姿态。"]
        eventLog.append(contentsOf: messages)
        return messages
    }

    public mutating func restUnit(id unitID: String) throws -> [String] {
        try ensureCampaignCanContinue()

        guard let index = units.firstIndex(where: { $0.id == unitID }) else {
            throw GameRuleError.missingEntity
        }

        guard units[index].faction == activeFaction else {
            throw GameRuleError.notActiveFaction
        }

        guard !units[index].hasActed else {
            throw GameRuleError.unitAlreadyActed
        }

        guard hasSupply(for: units[index]) else {
            throw GameRuleError.noSupply
        }

        let cost = EmpireResources(gold: 0, grain: 18, iron: 0, science: 0, prestige: 0)
        var pool = resources[activeFaction] ?? .zero
        try pool.spend(cost)
        resources[activeFaction] = pool

        let recovered = min(28, units[index].kind.maxHealth - units[index].health)
        units[index].health = min(units[index].kind.maxHealth, units[index].health + 28)
        units[index].hasMoved = true
        units[index].hasActed = true

        let messages = ["\(units[index].kind.displayName)完成休整，恢复 \(recovered) 点生命。"]
        eventLog.append(contentsOf: messages)
        return messages
    }

    public mutating func appointGeneral(unitID: String) throws -> [String] {
        try ensureCampaignCanContinue()

        guard let index = units.firstIndex(where: { $0.id == unitID }) else {
            throw GameRuleError.missingEntity
        }

        guard units[index].faction == activeFaction else {
            throw GameRuleError.notActiveFaction
        }

        guard units[index].generalName == nil else {
            throw GameRuleError.generalAlreadyAssigned
        }

        let cost = EmpireResources(gold: 55, grain: 0, iron: 0, science: 15, prestige: 2)
        var pool = resources[activeFaction] ?? .zero
        try pool.spend(cost)
        resources[activeFaction] = pool

        let usedNames = Set(units.compactMap(\.generalName))
        let candidateNames = ["庞培", "西庇阿", "布鲁图", "马略", "苏拉", "阿格里帕"]
        let name = candidateNames.first { !usedNames.contains($0) } ?? "罗马将领 \(units[index].experience + 1)"
        let trait = GeneralTrait.defaultTrait(forName: name) ?? .eagleStandard
        units[index].generalName = name
        units[index].generalTrait = trait
        units[index].experience += 2

        let messages = ["元老院任命\(name)（\(trait.displayName)）统率\(units[index].kind.displayName)。"]
        eventLog.append(contentsOf: messages)
        return messages
    }

    public mutating func useGeneralSkill(unitID: String) throws -> [String] {
        try ensureCampaignCanContinue()

        guard let commanderIndex = units.firstIndex(where: { $0.id == unitID }) else {
            throw GameRuleError.missingEntity
        }

        guard units[commanderIndex].faction == activeFaction else {
            throw GameRuleError.notActiveFaction
        }

        guard !units[commanderIndex].hasActed else {
            throw GameRuleError.unitAlreadyActed
        }

        guard let trait = units[commanderIndex].resolvedGeneralTrait,
              let generalName = units[commanderIndex].generalName else {
            throw GameRuleError.generalSkillUnavailable
        }

        guard units[commanderIndex].generalSkillCooldownRemaining == 0 else {
            throw GameRuleError.generalSkillOnCooldown
        }

        let preview = try generalSkillPreview(unitID: unitID)
        var messages: [String]

        switch trait {
        case .eagleStandard:
            let recovered = recoverFriendlyUnits(
                unitIDs: preview.affectedUnitIDs,
                amount: trait.recoveryAmount
            )
            units[commanderIndex].experience += 1
            messages = ["\(generalName)发动\(trait.skillName)，\(recovered.messageFragment)，鹰旗声望提升。"]

        case .siegeEngineer:
            guard preview.isExecutable else {
                throw GameRuleError.invalidTarget
            }
            let affectedCities = reduceEnemyFortifications(
                cityIDs: preview.affectedCityIDs,
                amount: trait.fortificationReductionAmount
            )
            guard !affectedCities.isEmpty else {
                throw GameRuleError.invalidTarget
            }
            messages = ["\(generalName)发动\(trait.skillName)，削弱\(affectedCities.joined(separator: "、"))城防。"]

        case .quartermaster, .shieldWall:
            let recovered = recoverFriendlyUnits(
                unitIDs: preview.affectedUnitIDs,
                amount: trait.recoveryAmount
            )
            messages = ["\(generalName)发动\(trait.skillName)，\(recovered.messageFragment)。"]
        }

        if let updatedCommanderIndex = units.firstIndex(where: { $0.id == unitID }) {
            units[updatedCommanderIndex].hasMoved = true
            units[updatedCommanderIndex].hasActed = true
            units[updatedCommanderIndex].generalSkillCooldownRemaining = trait.skillCooldownTurns
        }

        messages.append(contentsOf: evaluateCampaignProgress())
        eventLog.append(contentsOf: messages)
        return messages
    }

    public mutating func sendEnvoy(to target: Faction) throws -> [String] {
        try ensureCampaignCanContinue()

        guard target != activeFaction, target != .neutral else {
            throw GameRuleError.invalidDiplomacyTarget
        }

        guard Faction.turnOrder.contains(target) else {
            throw GameRuleError.invalidDiplomacyTarget
        }

        let current = diplomaticStatus(between: activeFaction, and: target)
        guard current != .alliance else {
            throw GameRuleError.invalidDiplomacyTarget
        }

        let cost = EmpireResources(gold: 45, grain: 0, iron: 0, science: 5, prestige: 1)
        var pool = resources[activeFaction] ?? .zero
        try pool.spend(cost)
        resources[activeFaction] = pool

        let nextStatus: DiplomaticStatus = current == .war ? .truce : .alliance
        setDiplomaticStatus(nextStatus, between: activeFaction, and: target)

        let messages = ["使节抵达\(target.displayName)，关系变为\(nextStatus.displayName)。"]
        eventLog.append(contentsOf: messages)
        return messages
    }

    public mutating func recruit(_ kind: UnitKind, at cityID: String) throws -> [String] {
        try ensureCampaignCanContinue()

        let preview = try recruitmentPreview(kind, at: cityID)
        guard preview.canRecruit,
              let spawnPosition = preview.deploymentPosition else {
            throw preview.blockingError ?? GameRuleError.invalidDestination
        }

        var pool = resources[activeFaction] ?? .zero
        try pool.spend(preview.cost)
        resources[activeFaction] = pool

        let unit = ArmyUnit(
            id: "\(activeFaction.rawValue)-\(kind.rawValue)-\(turn)-\(units.count + 1)",
            kind: kind,
            faction: activeFaction,
            position: spawnPosition
        )
        units.append(unit)

        var messages = ["\(preview.cityName)招募\(kind.displayName)。"]
        messages.append(contentsOf: evaluateCampaignProgress())
        eventLog.append(contentsOf: messages)
        return messages
    }

    public mutating func research(_ technology: Technology) throws -> [String] {
        try ensureCampaignCanContinue()

        var known = researchedTechnologies[activeFaction] ?? []
        guard !known.contains(technology) else {
            throw GameRuleError.technologyAlreadyResearched
        }

        var pool = resources[activeFaction] ?? .zero
        try pool.spend(technology.cost)
        resources[activeFaction] = pool
        known.insert(technology)
        researchedTechnologies[activeFaction] = known

        let messages = ["完成科技：\(technology.displayName)。"]
        eventLog.append(contentsOf: messages)
        return messages
    }

    public mutating func endTurn() -> [String] {
        guard !campaignStatus.isGameOver else {
            return [GameRuleError.campaignAlreadyEnded.displayMessage]
        }

        let gained = income(for: activeFaction)
        resources[activeFaction, default: .zero].add(gained)

        let previous = activeFaction
        let next = nextFaction(after: activeFaction)
        activeFaction = next

        if next == .rome {
            turn += 1
        }

        refreshFactionForNewTurn(activeFaction)

        let messages = [
            "\(previous.displayName)获得收入：金币 \(gained.gold)，粮食 \(gained.grain)，铁 \(gained.iron)，科技 \(gained.science)。",
            "第 \(turn) 回合：\(activeFaction.displayName)行动。"
        ]
        eventLog.append(contentsOf: messages)
        return messages
    }

    public mutating func performSimpleAI(for faction: Faction) -> [String] {
        guard !campaignStatus.isGameOver,
              faction == activeFaction,
              faction != .rome,
              faction != .neutral else {
            return []
        }

        var messages: [String] = []

        messages.append(contentsOf: performAIRecruitment(for: faction))

        let actingIDs = units.filter { $0.faction == faction }.map(\.id)

        for unitID in actingIDs {
            guard !campaignStatus.isGameOver else {
                break
            }

            guard let actingUnit = unit(withID: unitID), !actingUnit.hasActed else {
                continue
            }

            if let orderMessages = try? setTacticalOrder(unitID: unitID, order: preferredAITacticalOrder(for: actingUnit)) {
                messages.append(contentsOf: orderMessages)
            }

            guard !campaignStatus.isGameOver else {
                break
            }

            guard let orderedUnit = unit(withID: unitID) else {
                continue
            }

            if shouldAIRest(orderedUnit),
               let result = try? restUnit(id: unitID) {
                messages.append(contentsOf: result)
                continue
            }

            if shouldAIUseGeneralSkill(orderedUnit),
               let result = try? useGeneralSkill(unitID: unitID) {
                messages.append(contentsOf: result)
                if campaignStatus.isGameOver {
                    break
                }
                continue
            }

            if let target = bestAITarget(for: orderedUnit) {
                messages.append(contentsOf: performAIAttack(attackerID: unitID, defenderID: target.id))
                if campaignStatus.isGameOver {
                    break
                }
                continue
            }

            guard let destination = bestAIDestination(for: orderedUnit) else {
                if let refreshed = self.unit(withID: unitID),
                   shouldAIRest(refreshed),
                   let result = try? restUnit(id: unitID) {
                    messages.append(contentsOf: result)
                }
                continue
            }

            if let result = try? moveUnit(id: unitID, to: destination) {
                messages.append(contentsOf: result)

                guard !campaignStatus.isGameOver else {
                    break
                }

                if let movedUnit = self.unit(withID: unitID),
                   let target = bestAITarget(for: movedUnit) {
                    messages.append(contentsOf: performAIAttack(attackerID: unitID, defenderID: target.id))
                    if campaignStatus.isGameOver {
                        break
                    }
                }
            }
        }

        if messages.isEmpty {
            messages.append("\(faction.displayName)整备军团。")
            eventLog.append(messages.last ?? "")
        }

        return messages
    }

    private func nextFaction(after faction: Faction) -> Faction {
        let candidates = Faction.turnOrder.filter { candidate in
            units.contains { $0.faction == candidate } || cities.contains { $0.owner == candidate }
        }

        guard let index = candidates.firstIndex(of: faction) else {
            return .rome
        }

        return candidates[(index + 1) % candidates.count]
    }

    private func attackBonus(for attacker: ArmyUnit, against defender: ArmyUnit) -> Int {
        let known = researchedTechnologies[attacker.faction] ?? []
        var bonus = 0

        if known.contains(.marchingDrill), attacker.kind != .navy {
            bonus += 4
        }

        if known.contains(.navalCommand), attacker.kind == .navy {
            bonus += 6
        }

        if known.contains(.siegeEngineering), city(at: defender.position)?.owner == defender.faction {
            bonus += 8
        }

        if let trait = attacker.resolvedGeneralTrait {
            bonus += trait.attackBonus

            if city(at: defender.position)?.owner == defender.faction {
                bonus += trait.siegeAttackBonus
            }
        }

        bonus += attacker.resolvedTacticalOrder.attackBonus

        return bonus
    }

    private func estimatedDamage(from attacker: ArmyUnit, to defender: ArmyUnit) -> Int {
        estimatedDamage(from: attacker, to: defender, modifiers: combatModifiers(attacker: attacker, defender: defender))
    }

    private func estimatedDamage(from attacker: ArmyUnit, to defender: ArmyUnit, modifiers: CombatModifiers) -> Int {
        let attackerBonus = attackBonus(for: attacker, against: defender)
        let defenseBonus = defenseBonus(at: defender.position, faction: defender.faction)
        return max(
            12,
            attacker.kind.attack +
                attackerBonus +
                attacker.experience * 3 +
                modifiers.attackTotal -
                effectiveDefense(for: defender) -
                defenseBonus -
                modifiers.defenderSupportBonus
        )
    }

    private func retaliationDamage(from defender: ArmyUnit, to attacker: ArmyUnit) -> Int {
        max(6, effectiveAttack(for: defender) / 2 - effectiveDefense(for: attacker) / 2)
    }

    private func combatModifiers(attacker: ArmyUnit, defender: ArmyUnit) -> CombatModifiers {
        let supportCount = adjacentFriendlyUnitCount(
            around: attacker.position,
            faction: attacker.faction,
            excluding: [attacker.id]
        )
        let flankingCount = adjacentFriendlyUnitCount(
            around: defender.position,
            faction: attacker.faction,
            excluding: [attacker.id]
        )
        let defenderSupportCount = adjacentFriendlyUnitCount(
            around: defender.position,
            faction: defender.faction,
            excluding: [defender.id]
        )

        return CombatModifiers(
            supportBonus: min(2, supportCount) * 2,
            flankingBonus: min(2, flankingCount) * 3,
            commandBonus: commandBonus(for: attacker),
            defenderSupportBonus: min(2, defenderSupportCount) * 3
        )
    }

    private func adjacentFriendlyUnitCount(around position: Position, faction: Faction, excluding excludedIDs: Set<String>) -> Int {
        units.filter { unit in
            unit.faction == faction &&
                !excludedIDs.contains(unit.id) &&
                unit.position.hexDistance(to: position) <= 1
        }.count
    }

    private func commandBonus(for unit: ArmyUnit) -> Int {
        var bestBonus = 0

        for commander in units where commander.faction == unit.faction && commander.generalName != nil {
            let range = max(1, commander.resolvedGeneralTrait?.commandRange ?? 1)
            guard commander.position.hexDistance(to: unit.position) <= range else {
                continue
            }

            bestBonus = max(bestBonus, commander.id == unit.id ? 2 : 3)
        }

        return bestBonus
    }

    private mutating func setDiplomaticStatus(_ status: DiplomaticStatus, between first: Faction, and second: Faction) {
        let id = DiplomaticRelation.id(for: first, second)
        if let index = diplomaticRelations.firstIndex(where: { $0.id == id }) {
            diplomaticRelations[index].status = status
        } else {
            diplomaticRelations.append(DiplomaticRelation(first: first, second: second, status: status))
        }
    }

    private func defenseBonus(at position: Position, faction: Faction) -> Int {
        let terrain = tile(at: position)?.terrain.defenseBonus ?? 0
        let fortification = city(at: position)?.owner == faction ? city(at: position)?.fortification ?? 0 : 0
        return terrain + fortification
    }

    private func hasSupply(for unit: ArmyUnit) -> Bool {
        if let city = city(at: unit.position), city.owner == unit.faction || city.owner == .neutral {
            return true
        }

        return unit.position
            .neighbors(width: width, height: height)
            .contains { position in
                city(at: position)?.owner == unit.faction
        }
    }

    private mutating func refreshFactionForNewTurn(_ faction: Faction) {
        for index in units.indices where units[index].faction == faction {
            units[index].hasMoved = false
            units[index].hasActed = false
            units[index].tacticalOrder = nil
            units[index].generalSkillCooldownRemaining = max(0, units[index].generalSkillCooldownRemaining - 1)
        }
    }

    private func generalSkillPreview(for commander: ArmyUnit) -> GeneralSkillPreview {
        guard let trait = commander.resolvedGeneralTrait else {
            return GeneralSkillPreview(
                unitID: commander.id,
                trait: .eagleStandard,
                origin: commander.position,
                range: 0,
                rangePositions: [],
                affectedUnitIDs: [],
                affectedCityIDs: [],
                affectedPositions: [],
                projectedRecoveredHealth: 0,
                projectedFortificationReduction: 0,
                cooldownRemaining: commander.generalSkillCooldownRemaining,
                cooldownText: "无技能",
                isExecutable: false,
                blockedReason: "该单位没有可用将领技能",
                summary: "无可用技能",
                detail: "该单位没有可用将领技能"
            )
        }

        let range = trait.commandRange
        let rangePositions = positions(inRange: range, around: commander.position)
        let recoveryTargets = recoveryTargets(for: commander, range: range, amount: trait.recoveryAmount)
        let fortificationTargets = fortificationTargets(
            around: commander.position,
            faction: commander.faction,
            range: range,
            amount: trait.fortificationReductionAmount
        )
        let affectedUnitIDs = recoveryTargets.map { $0.id }
        let affectedCityIDs = fortificationTargets.map { $0.id }
        let projectedRecoveredHealth = recoveryTargets.reduce(0) { $0 + $1.recoveredHealth }
        let projectedFortificationReduction = fortificationTargets.reduce(0) { $0 + $1.reduction }
        let cooldownRemaining = commander.generalSkillCooldownRemaining
        let cooldownText = cooldownRemaining > 0 ? "冷却 \(cooldownRemaining) 回合" : "冷却就绪"

        let blockedReason: String?
        if campaignStatus.isGameOver {
            blockedReason = "战役已结束"
        } else if commander.faction != activeFaction {
            blockedReason = "非当前行动势力"
        } else if commander.hasActed {
            blockedReason = "本回合已行动"
        } else if cooldownRemaining > 0 {
            blockedReason = "技能冷却中（\(cooldownRemaining) 回合）"
        } else if trait == .siegeEngineer && fortificationTargets.isEmpty {
            blockedReason = "范围内没有可削弱敌城"
        } else {
            blockedReason = nil
        }

        let summary: String
        switch trait {
        case .siegeEngineer:
            if fortificationTargets.isEmpty {
                summary = "范围内没有可削弱敌城"
            } else {
                summary = "削弱 \(fortificationTargets.count) 座敌城共 \(projectedFortificationReduction) 城防"
            }

        case .eagleStandard, .quartermaster, .shieldWall:
            if recoveryTargets.isEmpty {
                summary = "阵线已满员"
            } else {
                summary = "恢复 \(recoveryTargets.count) 支友军共 \(projectedRecoveredHealth) 生命"
            }
        }

        let affectedPositions = sortedPositions(Array(Set(recoveryTargets.map { $0.position } + fortificationTargets.map { $0.position })))
        let detailParts = [
            "范围 \(range)",
            cooldownText,
            summary,
            blockedReason.map { "不可用：\($0)" }
        ].compactMap { $0 }

        return GeneralSkillPreview(
            unitID: commander.id,
            trait: trait,
            origin: commander.position,
            range: range,
            rangePositions: rangePositions,
            affectedUnitIDs: affectedUnitIDs,
            affectedCityIDs: affectedCityIDs,
            affectedPositions: affectedPositions,
            projectedRecoveredHealth: projectedRecoveredHealth,
            projectedFortificationReduction: projectedFortificationReduction,
            cooldownRemaining: cooldownRemaining,
            cooldownText: cooldownText,
            isExecutable: blockedReason == nil,
            blockedReason: blockedReason,
            summary: summary,
            detail: detailParts.joined(separator: " · ")
        )
    }

    private func positions(inRange range: Int, around origin: Position) -> [Position] {
        sortedPositions(tiles.map(\.position).filter { $0.hexDistance(to: origin) <= range })
    }

    private func sortedPositions(_ positions: [Position]) -> [Position] {
        positions.sorted { left, right in
            if left.y == right.y {
                return left.x < right.x
            }
            return left.y < right.y
        }
    }

    private func recoveryTargets(
        for commander: ArmyUnit,
        range: Int,
        amount: Int
    ) -> [(id: String, position: Position, recoveredHealth: Int)] {
        units.compactMap { unit in
            let candidate = unit.id == commander.id ? commander : unit
            guard candidate.faction == commander.faction,
                  candidate.position.hexDistance(to: commander.position) <= range,
                  candidate.health < candidate.kind.maxHealth else {
                return nil
            }

            return (
                id: candidate.id,
                position: candidate.position,
                recoveredHealth: min(amount, candidate.kind.maxHealth - candidate.health)
            )
        }
    }

    private func fortificationTargets(
        around origin: Position,
        faction: Faction,
        range: Int,
        amount: Int
    ) -> [(id: String, name: String, position: Position, reduction: Int)] {
        cities.compactMap { city in
            guard city.owner != faction,
                  city.owner != .neutral,
                  diplomaticStatus(between: faction, and: city.owner) == .war,
                  city.position.hexDistance(to: origin) <= range,
                  city.fortification > 1 else {
                return nil
            }

            return (
                id: city.id,
                name: city.name,
                position: city.position,
                reduction: min(amount, city.fortification - 1)
            )
        }
        .sorted { left, right in
            let leftDistance = left.position.hexDistance(to: origin)
            let rightDistance = right.position.hexDistance(to: origin)
            if leftDistance == rightDistance {
                return left.id < right.id
            }
            return leftDistance < rightDistance
        }
    }

    private mutating func recoverFriendlyUnits(
        unitIDs: [String],
        amount: Int
    ) -> (unitCount: Int, health: Int, messageFragment: String) {
        var recoveredUnitCount = 0
        var recoveredHealth = 0

        for unitID in unitIDs {
            guard let index = units.firstIndex(where: { $0.id == unitID }),
                  units[index].health < units[index].kind.maxHealth else {
                continue
            }

            let recovered = min(amount, units[index].kind.maxHealth - units[index].health)
            units[index].health += recovered
            recoveredUnitCount += 1
            recoveredHealth += recovered
        }

        if recoveredUnitCount == 0 {
            return (0, 0, "阵线已满员")
        }

        return (recoveredUnitCount, recoveredHealth, "恢复 \(recoveredUnitCount) 支友军共 \(recoveredHealth) 点生命")
    }

    private mutating func reduceEnemyFortifications(
        cityIDs: [String],
        amount: Int
    ) -> [String] {
        var affectedCities: [String] = []

        for cityID in cityIDs {
            guard let index = cities.firstIndex(where: { $0.id == cityID }),
                  cities[index].fortification > 1 else {
                continue
            }

            cities[index].fortification = max(1, cities[index].fortification - amount)
            affectedCities.append(cities[index].name)
        }

        return affectedCities
    }

    private mutating func captureCityIfPossible(at position: Position, by faction: Faction) -> [String] {
        guard let cityIndex = cities.firstIndex(where: { $0.position == position }),
              cities[cityIndex].owner != faction else {
            return []
        }

        guard cities[cityIndex].owner == .neutral ||
            diplomaticStatus(between: faction, and: cities[cityIndex].owner) == .war else {
            return []
        }

        guard unit(at: position)?.faction == faction else {
            return []
        }

        let oldOwner = cities[cityIndex].owner
        cities[cityIndex].owner = faction
        return ["\(faction.displayName)占领\(cities[cityIndex].name)，原属\(oldOwner.displayName)。"]
    }

    private func recruitmentBlockedReason(for kind: UnitKind, from _: City, error: GameRuleError?) -> String? {
        guard let error else { return nil }

        switch error {
        case .invalidDestination where kind == .navy:
            return "缺少相邻空港口"
        case .invalidDestination:
            return "城市地形无法部署"
        case .occupiedTile:
            return kind == .navy ? "港口已被占用" : "城市周边无空部署格"
        default:
            return error.displayMessage
        }
    }

    private func spawnPosition(for kind: UnitKind, from city: City) throws -> Position {
        if kind == .navy {
            let harborPositions = city.position
                .neighbors(width: width, height: height)
                .filter { position in
                    tile(at: position)?.terrain == .water
                }
            guard !harborPositions.isEmpty else {
                throw GameRuleError.invalidDestination
            }

            guard let harbor = harborPositions.first(where: { unit(at: $0) == nil }) else {
                throw GameRuleError.occupiedTile
            }

            return harbor
        }

        guard tile(at: city.position)?.terrain != .water else {
            throw GameRuleError.invalidDestination
        }

        if unit(at: city.position) == nil {
            return city.position
        }

        guard let paradeGround = city.position
            .neighbors(width: width, height: height)
            .first(where: { position in
                guard let tile = tile(at: position) else { return false }
                return kind.canEnter(tile.terrain) && unit(at: position) == nil
            }) else {
            throw GameRuleError.occupiedTile
        }

        return paradeGround
    }

    private static let campaignObjectiveMissionIDs: Set<String> = [
        "secure-sicily",
        "raise-legions",
        "break-carthage"
    ]

    private var campaignObjectiveMissions: [Mission] {
        missions.filter { mission in
            mission.requirement != nil || Self.campaignObjectiveMissionIDs.contains(mission.id)
        }
    }

    private func ensureCampaignCanContinue() throws {
        if campaignStatus.isGameOver {
            throw GameRuleError.campaignAlreadyEnded
        }
    }

    private func isMissionFulfilled(_ mission: Mission) -> Bool {
        isMissionRequirementSatisfied(for: mission)
    }

    private func isMissionRequirementSatisfied(for mission: Mission) -> Bool {
        if let requirement = mission.requirement {
            return isMissionRequirementSatisfied(requirement)
        }

        switch mission.id {
        case "secure-sicily":
            return city(withID: "syracuse")?.owner == .rome
        case "raise-legions":
            return units.filter { $0.faction == .rome }.count >= 5
        case "break-carthage":
            return city(withID: "carthage")?.owner == .rome
        default:
            return false
        }
    }

    private func isMissionRequirementSatisfied(_ requirement: MissionRequirement) -> Bool {
        switch requirement {
        case let .controlCity(cityID, faction):
            return city(withID: cityID)?.owner == faction
        case let .factionUnitCount(faction, atLeast):
            return units.filter { $0.faction == faction }.count >= atLeast
        }
    }

    private func missionProgressText(for mission: Mission) -> String? {
        guard let requirement = mission.requirement else {
            return nil
        }

        switch requirement {
        case let .controlCity(cityID, faction):
            let owner = city(withID: cityID)?.owner.displayName ?? "未知"
            return "\(owner)控制 / 目标\(faction.displayName)"
        case let .factionUnitCount(faction, atLeast):
            let count = units.filter { $0.faction == faction }.count
            return "\(count)/\(atLeast) 支\(faction.displayName)部队"
        }
    }

    private mutating func evaluateCampaignProgress() -> [String] {
        var messages = evaluateMissions()
        let status = campaignStatus

        switch status.kind {
        case .ongoing:
            break
        case .romanVictory:
            messages.append("战役胜利：\(status.detail)")
        case .romanDefeat:
            messages.append("战役失败：\(status.detail)")
        }

        return messages
    }

    private mutating func evaluateMissions() -> [String] {
        var messages: [String] = []

        for index in missions.indices where !missions[index].isCompleted {
            if isMissionRequirementSatisfied(for: missions[index]) {
                missions[index].isCompleted = true
                resources[.rome, default: .zero].add(missions[index].reward)
                messages.append("任务完成：\(missions[index].title)。")
            }
        }

        return messages
    }

    private mutating func performAIRecruitment(for faction: Faction) -> [String] {
        let ownedCities = cities
            .filter { $0.owner == faction }
            .sorted { left, right in
                aiFrontlineDistance(from: left.position, for: faction) < aiFrontlineDistance(from: right.position, for: faction)
            }

        let existingUnitCount = units.filter { $0.faction == faction }.count
        let targetUnitCount = min(ownedCities.count * 2 + 2, 7)
        guard existingUnitCount < targetUnitCount else {
            return []
        }

        for city in ownedCities {
            guard let kind = preferredAIRecruitmentKind(at: city, for: faction) else {
                continue
            }

            if let messages = try? recruit(kind, at: city.id) {
                return messages
            }
        }

        return []
    }

    private func preferredAIRecruitmentKind(at city: City, for faction: Faction) -> UnitKind? {
        let pool = resources[faction] ?? .zero
        let hasHarbor = city.position
            .neighbors(width: width, height: height)
            .contains { position in
                tile(at: position)?.terrain == .water && unit(at: position) == nil
            }
        let existingNavy = units.contains { $0.faction == faction && $0.kind == .navy }
        let romanEnemiesNearby = units.contains { enemy in
            enemy.faction == .rome &&
                diplomaticStatus(between: faction, and: enemy.faction) == .war &&
                city.position.hexDistance(to: enemy.position) <= 4
        }

        var candidates: [UnitKind] = []
        if hasHarbor, !existingNavy {
            candidates.append(.navy)
        }
        if romanEnemiesNearby {
            candidates.append(contentsOf: [.legion, .archer, .cavalry])
        } else {
            candidates.append(contentsOf: [.cavalry, .legion, .archer])
        }
        candidates.append(.archer)

        return candidates.first { kind in
            pool.canPay(kind.recruitmentCost) && (try? spawnPosition(for: kind, from: city)) != nil
        }
    }

    private func shouldAIRest(_ unit: ArmyUnit) -> Bool {
        guard unit.healthRatio <= 0.38,
              !unit.hasActed,
              hasSupply(for: unit),
              (resources[unit.faction] ?? .zero).canPay(EmpireResources(gold: 0, grain: 18, iron: 0, science: 0, prestige: 0)) else {
            return false
        }

        let nearbyEnemy = units.contains { enemy in
            enemy.faction != unit.faction &&
                diplomaticStatus(between: unit.faction, and: enemy.faction) == .war &&
                unit.position.hexDistance(to: enemy.position) <= max(2, enemy.kind.range)
        }

        return !nearbyEnemy || unit.healthRatio <= 0.24
    }

    private func shouldAIUseGeneralSkill(_ unit: ArmyUnit) -> Bool {
        guard !unit.hasActed,
              let trait = unit.resolvedGeneralTrait,
              unit.generalName != nil else {
            return false
        }

        let preview = generalSkillPreview(for: unit)

        switch trait {
        case .siegeEngineer:
            return preview.isExecutable && preview.projectedFortificationReduction > 0

        case .quartermaster, .shieldWall, .eagleStandard:
            return preview.isExecutable && aiSkillTargetUnit(for: unit, preview: preview) != nil
        }
    }

    private func aiSkillRecoveryThreshold(for trait: GeneralTrait) -> Double {
        switch trait {
        case .quartermaster:
            return 0.72
        case .shieldWall:
            return 0.64
        case .eagleStandard:
            return 0.55
        case .siegeEngineer:
            return 0
        }
    }

    private func preferredAITacticalOrder(for unit: ArmyUnit) -> TacticalOrder {
        let nearbyEnemyDistance = units
            .filter { enemy in
                enemy.faction != unit.faction &&
                    enemy.faction != .neutral &&
                    diplomaticStatus(between: unit.faction, and: enemy.faction) == .war
            }
            .map { unit.position.hexDistance(to: $0.position) }
            .min()

        if unit.healthRatio <= 0.34 {
            return .defensive
        }

        if let target = bestAITarget(for: unit) {
            let assaultUnit = ArmyUnit(
                id: unit.id,
                kind: unit.kind,
                faction: unit.faction,
                position: unit.position,
                health: unit.health,
                experience: unit.experience,
                generalName: unit.generalName,
                generalTrait: unit.generalTrait,
                generalSkillCooldownRemaining: unit.generalSkillCooldownRemaining,
                tacticalOrder: .assault,
                hasMoved: unit.hasMoved,
                hasActed: unit.hasActed
            )

            if (aiCombatPreview(attacker: assaultUnit, defender: target)?.damage ?? 0) >= target.health {
                return .assault
            }

            if unit.healthRatio <= 0.58 {
                return .defensive
            }

            return .assault
        }

        if let nearbyEnemyDistance, nearbyEnemyDistance <= 2, unit.healthRatio <= 0.62 {
            return .defensive
        }

        let objectives = aiObjectivePositions(for: unit.faction)
        let nearestObjectiveDistance = objectives.map { unit.position.hexDistance(to: $0) }.min() ?? 0
        if nearestObjectiveDistance > effectiveMovement(for: unit) + unit.kind.range,
           nearbyEnemyDistance.map({ $0 > 2 }) ?? true {
            return .forcedMarch
        }

        if let city = city(at: unit.position),
           city.owner == unit.faction,
           nearbyEnemyDistance.map({ $0 <= 3 }) ?? false {
            return .defensive
        }

        return .balanced
    }

    private mutating func performAIAttack(attackerID: String, defenderID: String) -> [String] {
        (try? attack(attackerID: attackerID, defenderID: defenderID)) ?? []
    }

    private func bestAITarget(for unit: ArmyUnit) -> ArmyUnit? {
        attackTargets(for: unit)
            .max { left, right in
                aiAttackScore(attacker: unit, defender: left) < aiAttackScore(attacker: unit, defender: right)
            }
    }

    private func aiAttackScore(attacker: ArmyUnit, defender: ArmyUnit) -> Int {
        guard let preview = aiCombatPreview(attacker: attacker, defender: defender) else {
            return Int.min / 4
        }

        let damage = preview.damage
        var score = damage * 4 - defender.health

        if damage >= defender.health {
            score += 160
        }

        if defender.faction == .rome {
            score += 45
        }

        if let city = city(at: defender.position), city.owner == defender.faction {
            score += 35 + city.production.gold / 2 + city.fortification
        }

        score += defender.experience * 8
        if defender.generalName != nil {
            score += 30
        }

        if attacker.resolvedTacticalOrder == .assault {
            score += 18
        }

        if defender.resolvedTacticalOrder == .defensive {
            score -= 18
        }

        return score
    }

    private func aiCombatPreview(attacker: ArmyUnit, defender: ArmyUnit) -> CombatPreview? {
        var forecast = self
        forecast.activeFaction = attacker.faction

        guard let attackerIndex = forecast.units.firstIndex(where: { $0.id == attacker.id }) else {
            return nil
        }

        forecast.units[attackerIndex] = attacker
        return try? forecast.attackPreview(attackerID: attacker.id, defenderID: defender.id)
    }

    private func aiFrontlineDistance(from position: Position, for faction: Faction) -> Int {
        let objectives = aiObjectivePositions(for: faction)
        return objectives.map { position.hexDistance(to: $0) }.min() ?? Int.max
    }

    private func aiObjectivePositions(for faction: Faction) -> [Position] {
        let cityObjectives = cities
            .filter { city in
                city.owner != faction &&
                    (city.owner == .neutral || diplomaticStatus(between: faction, and: city.owner) == .war)
            }
            .map(\.position)

        let unitObjectives = units
            .filter { unit in
                unit.faction != faction &&
                    unit.faction != .neutral &&
                    diplomaticStatus(between: faction, and: unit.faction) == .war
            }
            .map(\.position)

        return unitObjectives + cityObjectives
    }

    private func aiPositionScore(_ position: Position, for unit: ArmyUnit) -> Int {
        let objectives = aiObjectivePositions(for: unit.faction)
        let closestObjectiveDistance = objectives.map { position.hexDistance(to: $0) }.min() ?? 0
        var score = -closestObjectiveDistance * 18

        for enemy in units where enemy.faction != unit.faction && diplomaticStatus(between: unit.faction, and: enemy.faction) == .war {
            let distance = position.hexDistance(to: enemy.position)
            if distance <= unit.kind.range {
                let movedAttacker = ArmyUnit(
                    id: unit.id,
                    kind: unit.kind,
                    faction: unit.faction,
                    position: position,
                    health: unit.health,
                    experience: unit.experience,
                    generalName: unit.generalName,
                    generalTrait: unit.generalTrait,
                    generalSkillCooldownRemaining: unit.generalSkillCooldownRemaining,
                    tacticalOrder: unit.tacticalOrder,
                    hasMoved: true,
                    hasActed: unit.hasActed
                )
                score += aiAttackScore(attacker: movedAttacker, defender: enemy) + 140
            } else {
                score += max(0, 7 - distance) * 8
            }

            if enemy.faction == .rome {
                score += max(0, 6 - distance) * 4
            }
        }

        if let city = city(at: position), city.owner != unit.faction {
            score += city.owner == .neutral ? 70 : 115
        }

        if let terrain = tile(at: position)?.terrain {
            score += terrain.defenseBonus
            if terrain == .road {
                score += 4
            }
        }

        return score
    }

    private func aiIntent(for unit: ArmyUnit) -> AIIntent? {
        let order = preferredAITacticalOrder(for: unit)
        let orderedUnit = aiPlanningUnit(from: unit, order: order)

        if shouldAIRest(orderedUnit) {
            return AIIntent(
                unitID: unit.id,
                faction: unit.faction,
                kind: .regroup,
                tacticalOrder: order,
                destination: unit.position,
                threatScore: max(35, 100 - unit.health)
            )
        }

        if shouldAIUseGeneralSkill(orderedUnit) {
            let preview = generalSkillPreview(for: orderedUnit)
            return AIIntent(
                unitID: unit.id,
                faction: unit.faction,
                kind: .useSkill,
                tacticalOrder: order,
                targetUnitID: aiSkillTargetUnit(for: orderedUnit, preview: preview)?.id,
                targetCityID: aiSkillTargetCity(for: orderedUnit, preview: preview)?.id,
                destination: unit.position,
                threatScore: aiSkillThreatScore(for: orderedUnit, preview: preview)
            )
        }

        if let target = bestAITarget(for: orderedUnit) {
            let preview = aiCombatPreview(attacker: orderedUnit, defender: target)
            return AIIntent(
                unitID: unit.id,
                faction: unit.faction,
                kind: .attack,
                tacticalOrder: order,
                targetUnitID: target.id,
                destination: unit.position,
                projectedDamage: preview?.damage,
                threatScore: 500 + aiAttackScore(attacker: orderedUnit, defender: target)
            )
        }

        guard let destination = bestAIDestination(for: orderedUnit) else {
            return AIIntent(
                unitID: unit.id,
                faction: unit.faction,
                kind: .defend,
                tacticalOrder: order,
                targetCityID: city(at: unit.position)?.id,
                destination: unit.position,
                threatScore: aiDefensiveThreatScore(for: orderedUnit)
            )
        }

        let movedUnit = aiPlanningUnit(from: orderedUnit, position: destination, hasMoved: true)
        if let target = bestAITarget(for: movedUnit) {
            let preview = aiCombatPreview(attacker: movedUnit, defender: target)
            return AIIntent(
                unitID: unit.id,
                faction: unit.faction,
                kind: .advanceAttack,
                tacticalOrder: order,
                targetUnitID: target.id,
                destination: destination,
                projectedDamage: preview?.damage,
                threatScore: 420 + aiAttackScore(attacker: movedUnit, defender: target)
            )
        }

        if let city = capturableCity(at: destination, by: orderedUnit.faction) {
            return AIIntent(
                unitID: unit.id,
                faction: unit.faction,
                kind: .captureCity,
                tacticalOrder: order,
                targetCityID: city.id,
                destination: destination,
                threatScore: 360 + city.production.gold + city.production.prestige * 20 + city.fortification
            )
        }

        return AIIntent(
            unitID: unit.id,
            faction: unit.faction,
            kind: order == .defensive ? .defend : .advance,
            tacticalOrder: order,
            targetCityID: nearestAICityObjective(from: destination, for: unit.faction)?.id,
            destination: destination,
            threatScore: 140 + aiPositionScore(destination, for: orderedUnit)
        )
    }

    private func aiPlanningUnit(
        from unit: ArmyUnit,
        order: TacticalOrder? = nil,
        position: Position? = nil,
        hasMoved: Bool? = nil,
        hasActed: Bool? = nil
    ) -> ArmyUnit {
        ArmyUnit(
            id: unit.id,
            kind: unit.kind,
            faction: unit.faction,
            position: position ?? unit.position,
            health: unit.health,
            experience: unit.experience,
            generalName: unit.generalName,
            generalTrait: unit.generalTrait,
            generalSkillCooldownRemaining: unit.generalSkillCooldownRemaining,
            tacticalOrder: (order ?? unit.resolvedTacticalOrder) == .balanced ? nil : (order ?? unit.resolvedTacticalOrder),
            hasMoved: hasMoved ?? unit.hasMoved,
            hasActed: hasActed ?? unit.hasActed
        )
    }

    private func aiSkillThreatScore(for unit: ArmyUnit, preview: GeneralSkillPreview) -> Int {
        var score = 260 + (unit.generalName == nil ? 0 : 35)
        score += min(130, preview.projectedRecoveredHealth * 2)
        score += min(130, preview.projectedFortificationReduction * 18)
        if preview.blockedReason == nil {
            score += 20
        }
        return score
    }

    private func aiSkillTargetUnit(for unit: ArmyUnit, preview: GeneralSkillPreview) -> ArmyUnit? {
        guard let trait = unit.resolvedGeneralTrait,
              trait != .siegeEngineer else {
            return nil
        }

        let targetIDs = Set(preview.affectedUnitIDs)
        let threshold = aiSkillRecoveryThreshold(for: trait)
        return units
            .filter { ally in
                targetIDs.contains(ally.id) &&
                    ally.healthRatio <= threshold
            }
            .sorted { left, right in
                if left.health == right.health {
                    let leftDistance = left.position.hexDistance(to: unit.position)
                    let rightDistance = right.position.hexDistance(to: unit.position)
                    if leftDistance == rightDistance {
                        return left.id < right.id
                    }
                    return leftDistance < rightDistance
                }
                return left.health < right.health
            }
            .first
    }

    private func aiSkillTargetCity(for unit: ArmyUnit, preview: GeneralSkillPreview) -> City? {
        guard unit.resolvedGeneralTrait == .siegeEngineer else {
            return nil
        }

        let targetIDs = Set(preview.affectedCityIDs)
        return cities
            .filter { targetIDs.contains($0.id) }
            .sorted { left, right in
                if left.position.hexDistance(to: unit.position) == right.position.hexDistance(to: unit.position) {
                    return left.id < right.id
                }
                return left.position.hexDistance(to: unit.position) < right.position.hexDistance(to: unit.position)
            }
            .first
    }

    private func capturableCity(at position: Position, by faction: Faction) -> City? {
        guard let city = city(at: position),
              city.owner != faction,
              city.owner == .neutral || diplomaticStatus(between: faction, and: city.owner) == .war else {
            return nil
        }

        return city
    }

    private func nearestAICityObjective(from position: Position, for faction: Faction) -> City? {
        cities
            .filter { city in
                city.owner != faction &&
                    (city.owner == .neutral || diplomaticStatus(between: faction, and: city.owner) == .war)
            }
            .sorted { left, right in
                let leftDistance = position.hexDistance(to: left.position)
                let rightDistance = position.hexDistance(to: right.position)
                if leftDistance == rightDistance {
                    return left.id < right.id
                }
                return leftDistance < rightDistance
            }
            .first
    }

    private func aiDefensiveThreatScore(for unit: ArmyUnit) -> Int {
        let nearbyEnemyPressure = units.reduce(0) { partial, enemy in
            guard enemy.faction != unit.faction,
                  enemy.faction != .neutral,
                  diplomaticStatus(between: unit.faction, and: enemy.faction) == .war else {
                return partial
            }

            return partial + max(0, 5 - unit.position.hexDistance(to: enemy.position)) * 12
        }

        let cityValue = city(at: unit.position).map { $0.fortification + $0.production.gold / 2 } ?? 0
        return 80 + nearbyEnemyPressure + cityValue
    }

    private func bestAIDestination(for unit: ArmyUnit) -> Position? {
        let reachable = reachablePositions(for: unit)
        guard !reachable.isEmpty else {
            return nil
        }

        let ranked = reachable.sorted { left, right in
            let leftScore = aiPositionScore(left, for: unit)
            let rightScore = aiPositionScore(right, for: unit)
            if leftScore == rightScore {
                if left.y == right.y {
                    return left.x < right.x
                }
                return left.y < right.y
            }
            return leftScore > rightScore
        }

        return ranked.first
    }
}
