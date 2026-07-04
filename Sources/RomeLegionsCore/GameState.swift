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
        self.isExecutable = isExecutable
        self.blockedReason = blockedReason
        self.summary = summary
        self.detail = detail
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
    public var tacticalOrder: TacticalOrder?
    public var hasMoved: Bool
    public var hasActed: Bool

    public init(
        id: String,
        kind: UnitKind,
        faction: Faction,
        position: Position,
        health: Int? = nil,
        experience: Int = 0,
        generalName: String? = nil,
        generalTrait: GeneralTrait? = nil,
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
        self.tacticalOrder = tacticalOrder
        self.hasMoved = hasMoved
        self.hasActed = hasActed
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

    public func effectiveDefense(for unit: ArmyUnit) -> Int {
        max(1, unit.kind.defense + (unit.resolvedGeneralTrait?.defenseBonus ?? 0) + unit.resolvedTacticalOrder.defenseBonus)
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

        var forecast = self
        forecast.activeFaction = faction

        for index in forecast.units.indices where forecast.units[index].faction == faction {
            forecast.units[index].hasMoved = false
            forecast.units[index].hasActed = false
            forecast.units[index].tacticalOrder = nil
        }

        return forecast.units
            .filter { $0.faction == faction }
            .compactMap { forecast.aiIntent(for: $0) }
            .sorted { left, right in
                if left.threatScore == right.threatScore {
                    return left.unitID < right.unitID
                }
                return left.threatScore > right.threatScore
            }
            .prefix(max(0, limit))
            .map { $0 }
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

        guard cities[cityIndex].owner == activeFaction else {
            throw GameRuleError.cityNotOwned
        }

        let cost = EmpireResources(gold: 70, grain: 40, iron: 35, science: 0, prestige: 0)
        var pool = resources[activeFaction] ?? .zero
        try pool.spend(cost)
        resources[activeFaction] = pool

        cities[cityIndex].production.add(EmpireResources(gold: 10, grain: 8, iron: 6, science: 4, prestige: 1))
        cities[cityIndex].fortification += 3

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

        guard let city = city(withID: cityID) else {
            throw GameRuleError.missingEntity
        }

        guard city.owner == activeFaction else {
            throw GameRuleError.cityNotOwned
        }

        let spawnPosition = try spawnPosition(for: kind, from: city)

        guard unit(at: spawnPosition) == nil else {
            throw GameRuleError.occupiedTile
        }

        var pool = resources[activeFaction] ?? .zero
        try pool.spend(kind.recruitmentCost)
        resources[activeFaction] = pool

        let unit = ArmyUnit(
            id: "\(activeFaction.rawValue)-\(kind.rawValue)-\(turn)-\(units.count + 1)",
            kind: kind,
            faction: activeFaction,
            position: spawnPosition
        )
        units.append(unit)

        var messages = ["\(city.name)招募\(kind.displayName)。"]
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

        for index in units.indices where units[index].faction == activeFaction {
            units[index].hasMoved = false
            units[index].hasActed = false
            units[index].tacticalOrder = nil
        }

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

        let blockedReason: String?
        if campaignStatus.isGameOver {
            blockedReason = "战役已结束"
        } else if commander.faction != activeFaction {
            blockedReason = "非当前行动势力"
        } else if commander.hasActed {
            blockedReason = "本回合已行动"
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

    private func spawnPosition(for kind: UnitKind, from city: City) throws -> Position {
        if kind == .navy {
            guard let harbor = city.position
                .neighbors(width: width, height: height)
                .first(where: { position in
                    tile(at: position)?.terrain == .water && unit(at: position) == nil
                }) else {
                throw GameRuleError.invalidDestination
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
            return aiSkillTargetUnit(for: unit, preview: preview) != nil
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
