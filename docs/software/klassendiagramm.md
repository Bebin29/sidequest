# Klassendiagramm - Sidequest

## Gesamtarchitektur

```mermaid
classDiagram
    direction TB

    %% ============================================================
    %% MODELS (Swift)
    %% ============================================================

    class User {
        +UUID id
        +String email
        +String username
        +String displayName
        +String? profileImageUrl
        +String createdAt
        +String? updatedAt
        +String? lastSeenAt
        +String? bio
        +[String:String]? preferences
        +[String] favoriteCategories
        +Bool isVerified
        +Bool isModerator
        +Bool isPrivate
        +String? fcmToken
        +[String:Int]? stats
    }

    class Location {
        +UUID id
        +String name
        +String address
        +Double latitude
        +Double longitude
        +String geohash
        +String category
        +Double averageRating
        +Int totalRatings
        +String createdAt
        +String? updatedAt
        +UUID createdBy
        +String? description
        +[String] imageUrls
        +String? thumbnailUrl
        +[String] tags
        +String? priceRange
        +OpeningHours? openingHours
        +ParkingInfo? parkingInfo
        +AccessibilityInfo? accessibility
        +String? noiseLevel
        +Bool? wifiAvailable
        +Bool? isDogFriendly
        +Bool? isFamilyFriendly
        +String? phoneNumber
        +String? website
        +String? instagramHandle
        +Bool isVerified
        +Int reportCount
        +Double? trendingScore
        +String? creatorUsername
        +String? creatorDisplayName
        +String? creatorProfileImageUrl
    }

    class Trip {
        +UUID id
        +UUID userId
        +String username
        +String name
        +String? description
        +Int locationCount
        +String createdAt
        +String? updatedAt
        +String? startDate
        +String? endDate
        +String? coverImageUrl
        +Bool isCollaborative
        +Bool isPublic
        +Int viewCount
        +String? reminderDate
    }

    class Rating {
        +UUID id
        +UUID locationId
        +String locationName
        +UUID userId
        +String username
        +String? userProfileImageUrl
        +Int rating
        +String? comment
        +[String] imageUrls
        +[String] thumbnailUrls
        +String createdAt
        +String? updatedAt
        +UUID? tripId
        +Bool isVerified
        +String? verifiedAt
        +Int reportCount
        +Bool isHidden
        +Int reactionCount
        +Int commentCount
        +Int helpfulCount
        +String? visitDate
        +Double? priceSpent
        +Bool? wouldRecommend
    }

    class Comment {
        +UUID id
        +UUID locationId
        +UUID userId
        +String username
        +String text
        +String createdAt
    }

    class Friendship {
        +UUID id
        +UUID requesterId
        +UUID receiverId
        +FriendshipStatus status
        +String createdAt
        +String? acceptedAt
        +String requesterUsername
        +String receiverUsername
        +String? requesterDisplayName
        +String? requesterProfileImageUrl
        +Int? mutualCount
        +String? receiverDisplayName
        +String? receiverProfileImageUrl
        +Int? requesterSpotCount
        +Int? receiverSpotCount
    }

    class Notification {
        +UUID id
        +UUID recipientId
        +UUID senderId
        +String type
        +String title
        +String body
        +JSON data
        +Bool isRead
        +String createdAt
    }

    class FriendSuggestion {
        +UUID id
        +String username
        +String? displayName
        +String? profileImageUrl
        +Int mutualCount
        +[String] mutualUsernames
    }

    %% ============================================================
    %% ENUMS
    %% ============================================================

    class LocationCategory {
        <<enumeration>>
        restaurant
        cafe
        bar
        club
        bakery
        fastFood
        iceCream
        hotel
        cinema
        gym
        spa
        landmark
        park
        museum
        shopping
        viewpoint
        beach
        other
        +color() Color
    }

    class PriceRange {
        <<enumeration>>
        budget
        moderate
        upscale
        luxury
    }

    class NoiseLevel {
        <<enumeration>>
        quiet
        moderate
        loud
        veryLoud
    }

    class FriendshipStatus {
        <<enumeration>>
        pending
        accepted
        declined
        blocked
    }

    class HTTPMethod {
        <<enumeration>>
        get
        post
        put
        delete
    }

    class AppError {
        <<enumeration>>
        network(Error)
        decoding(Error)
        server(Int, String?)
        notFound
        unauthorized
        unknown(Error?)
        +errorDescription String?
    }

    %% ============================================================
    %% VALUE TYPES (eingebettete Structs)
    %% ============================================================

    class OpeningHours {
        +DayHours? monday
        +DayHours? tuesday
        +DayHours? wednesday
        +DayHours? thursday
        +DayHours? friday
        +DayHours? saturday
        +DayHours? sunday
    }

    class DayHours {
        +String openTime
        +String closeTime
        +Bool isClosed
    }

    class ParkingInfo {
        +Bool hasParking
        +String? parkingType
        +Bool? isFree
        +String? notes
    }

    class AccessibilityInfo {
        +Bool wheelchairAccessible
        +Bool hasElevator
        +Bool hasAccessibleRestroom
    }

    class LocationFilter {
        +LocationCategory? category
        +String? search
        +Double? latitude
        +Double? longitude
        +Double? radiusMeters
        +isEmpty Bool
    }

    class ServerStatus {
        +String status
        +String timestamp
        +ServerInfo server
        +DatabaseInfo database
        +TableCounts? tables
        +isHealthy Bool
        +formattedUptime String
    }

    class ServerInfo {
        +Int uptimeSeconds
        +String nodeVersion
        +MemoryInfo memoryMb
    }

    class MemoryInfo {
        +Int rss
        +Int heapUsed
        +Int heapTotal
    }

    class DatabaseInfo {
        +Bool connected
        +Int? responseMs
        +String? serverTime
        +String? error
    }

    class TableCounts {
        +Int users
        +Int locations
        +Int ratings
        +Int comments
        +Int friendships
        +Int notifications
    }

    %% ============================================================
    %% API RESPONSE TYPES
    %% ============================================================

    class APIResponse~T~ {
        +T data
    }

    class APIListResponse~T~ {
        +[T] data
        +Int count
    }

    class APIErrorResponse {
        +String error
    }

    class APIMessageResponse {
        +String message
    }

    class FeedResponse {
        +[Location] data
        +Int count
        +Bool hasMore
    }

    %% ============================================================
    %% VIEW MODELS
    %% ============================================================

    class AuthViewModel {
        +User? currentUser
        +Bool isAuthenticated
        +Bool needsOnboarding
        +Bool isLoading
        +String? errorMessage
        -AuthService authService
        +handleAppleSignIn(Result) void
        +signIn(String, String?, String?) async
        +checkExistingSession() async
        +signOut() void
        +deleteAccount() async
    }

    class MapViewModel {
        +[Location] locations
        +Bool isLoading
        +String? errorMessage
        +LocationFilter filter
        -LocationService locationService
        +loadLocations(UUID) async
        +addLocation([String:Any]) async Bool
    }

    class FeedViewModel {
        +[Location] locations
        +Bool isLoading
        +Bool isLoadingMore
        +Bool hasMore
        +String? errorMessage
        +Int currentIndex
        +[UUID:Color] dominantColors
        +CLLocation? userLocation
        -FeedService feedService
        +currentDominantColor Color?
        +setDominantColor(Color, UUID) void
        +fetchLocation() async
        +sortByDistance() void
        +loadFeed(UUID) async
        +loadMore(UUID) async
    }

    class FriendsViewModel {
        +[Friendship] friends
        +[Friendship] pendingRequests
        +[Friendship] sentRequests
        +[FriendSuggestion] suggestions
        +[User] searchResults
        +Bool isLoading
        +String? errorMessage
        +String? successMessage
        -FriendshipService service
        +loadFriends(UUID) async
        +loadPendingRequests(UUID) async
        +loadSentRequests(UUID) async
        +loadSuggestions(UUID) async
        +searchUsers(String) async
        +sendRequest(UUID, String) async
        +acceptRequest(UUID, UUID) async
        +declineRequest(UUID, UUID) async
        +withdrawRequest(UUID, UUID) async
        +removeFriend(UUID, UUID) async
    }

    class LocationDetailViewModel {
        +[Comment] comments
        +Bool isLoading
        +String? errorMessage
        -CommentService commentService
        +loadComments(UUID) async
        +addComment(UUID, UUID, String) async
    }

    class AdminViewModel {
        +[User] users
        +ServerStatus? serverStatus
        +String? monitoringError
        +Bool isLoading
        +String? errorMessage
        -UserService userService
        -NetworkService networkService
        +loadAll() async
        +loadUsers() async
        +loadServerStatus() async
    }

    %% ============================================================
    %% SERVICES
    %% ============================================================

    class NetworkServiceProtocol {
        <<interface>>
        +request~T~(String, HTTPMethod) async T
    }

    class NetworkService {
        -URLSession session
        +request~T~(String, HTTPMethod) async T
    }

    class AuthService {
        -URLSession session
        +signInWithApple(String, String?, String?) async (User, Bool)
    }

    class LocationService {
        -URLSession session
        +getLocation(UUID) async Location
        +fetchLocations(UUID, LocationFilter) async [Location]
        +createLocation([String:Any]) async Location
        +updateLocation(UUID, [String:Any]) async Location
        +deleteLocation(UUID) async
    }

    class FeedService {
        -URLSession session
        +fetchFeed(UUID, Int, Int) async FeedResponse
    }

    class CommentService {
        -URLSession session
        +fetchComments(UUID) async [Comment]
        +createComment(UUID, UUID, String) async Comment
    }

    class FriendshipService {
        -URLSession session
        +searchUsers(String) async [User]
        +sendRequest(UUID, String) async Friendship
        +getFriends(UUID) async [Friendship]
        +getPendingRequests(UUID) async [Friendship]
        +getSentRequests(UUID) async [Friendship]
        +updateStatus(UUID, String) async Friendship
        +getSuggestions(UUID) async [FriendSuggestion]
        +removeFriend(UUID) async
    }

    class UserService {
        -URLSession session
        +fetchUsers() async [User]
    }

    class ProfileService {
        -URLSession session
        +getUser(UUID) async User
        +checkUsername(String) async Bool
        +updateProfile(UUID, [String:Any]) async User
    }

    class ImageUploadService {
        -URLSession session
        +upload(UIImage) async String
        -resize(UIImage, CGFloat)$ UIImage
    }

    class PushNotificationService {
        +Bool isAuthorized
        +String? deviceToken
        +DeepLinkRouter router
        -ProfileService profileService
        +requestAuthorization() async Bool
        +uploadToken(UUID, String) async
    }

    class DependencyContainer {
        +NetworkServiceProtocol networkService
        +init(NetworkServiceProtocol)
    }

    %% ============================================================
    %% BACKEND CONTROLLERS (Node.js)
    %% ============================================================

    class AuthController {
        <<controller>>
        +signInWithApple(req, res)
    }

    class UserController {
        <<controller>>
        +getAll(req, res, query)
        +getById(req, res, id)
        +create(req, res)
        +update(req, res, id)
        +remove(req, res, id)
        +checkUsername(req, res, query)
    }

    class LocationController {
        <<controller>>
        +getAll(req, res, query)
        +getById(req, res, id)
        +create(req, res)
        +update(req, res, id)
        +remove(req, res, id)
        +getFeed(req, res, query)
    }

    class CommentController {
        <<controller>>
        +getByLocation(req, res, locationId)
        +create(req, res)
        +remove(req, res, id)
    }

    class FriendshipController {
        <<controller>>
        +sendRequest(req, res)
        +getSuggestions(req, res, userId)
        +getFriends(req, res, userId)
        +getPendingRequests(req, res, userId)
        +getSentRequests(req, res, userId)
        +updateStatus(req, res, id)
        +remove(req, res, id)
        +searchUsers(req, res, query)
    }

    class NotificationController {
        <<controller>>
        +getByUser(req, res, userId, query)
        +getUnreadCount(req, res, userId)
        +markRead(req, res, id)
        +markAllRead(req, res, userId)
    }

    class MonitoringController {
        <<controller>>
        +getStatus(req, res)
    }

    class UploadController {
        <<controller>>
        +upload(req, res)
    }

    %% ============================================================
    %% BACKEND SERVICES (Node.js)
    %% ============================================================

    class NotificationService {
        <<service>>
        +isEnabled(preferences, type) Bool
        +createAndSend(options)
        +notifyFriendRequest(senderId, receiverId)
        +notifyFriendAccepted(accepterId, requesterId)
        +notifyNewComment(commenterId, locationId)
        +notifyFriendNewSpot(creatorId, locationName)
    }

    class APNsService {
        <<service>>
        -KEY_PATH
        -KEY_ID
        -TEAM_ID
        -BUNDLE_ID
        +isConfigured() Bool
        +getSigningKey()
        +getToken()
        +getClient()
        +sendPush(deviceToken, options)
    }

    %% ============================================================
    %% BEZIEHUNGEN: Models
    %% ============================================================

    User "1" --> "*" Location : erstellt
    User "1" --> "*" Rating : verfasst
    User "1" --> "*" Comment : schreibt
    User "1" --> "*" Trip : besitzt
    User "1" --> "*" Notification : empfaengt

    Location "1" --> "*" Rating : hat
    Location "1" --> "*" Comment : hat
    Location "*" --> "1" LocationCategory : gehoert zu
    Location "1" --> "1" OpeningHours : hat
    Location "1" --> "1" ParkingInfo : hat
    Location "1" --> "1" AccessibilityInfo : hat

    OpeningHours "1" --> "*" DayHours : enthaelt

    Rating "*" --> "0..1" Trip : gehoert zu

    Friendship --> User : requester
    Friendship --> User : receiver
    Friendship --> FriendshipStatus : hat Status

    FriendSuggestion --> User : vorgeschlagen

    Notification --> User : sender
    Notification --> User : empfaenger

    Trip "1" --> "*" User : Teilnehmer

    ServerStatus --> ServerInfo : enthaelt
    ServerStatus --> DatabaseInfo : enthaelt
    ServerStatus --> TableCounts : enthaelt
    ServerInfo --> MemoryInfo : enthaelt

    %% ============================================================
    %% BEZIEHUNGEN: ViewModel -> Service
    %% ============================================================

    AuthViewModel --> AuthService : nutzt
    MapViewModel --> LocationService : nutzt
    FeedViewModel --> FeedService : nutzt
    FriendsViewModel --> FriendshipService : nutzt
    LocationDetailViewModel --> CommentService : nutzt
    AdminViewModel --> UserService : nutzt
    AdminViewModel --> NetworkService : nutzt
    PushNotificationService --> ProfileService : nutzt

    %% ============================================================
    %% BEZIEHUNGEN: ViewModel -> Model
    %% ============================================================

    AuthViewModel --> User : verwaltet
    MapViewModel --> Location : verwaltet
    MapViewModel --> LocationFilter : verwendet
    FeedViewModel --> Location : verwaltet
    FriendsViewModel --> Friendship : verwaltet
    FriendsViewModel --> FriendSuggestion : verwaltet
    FriendsViewModel --> User : sucht
    LocationDetailViewModel --> Comment : verwaltet
    AdminViewModel --> User : verwaltet
    AdminViewModel --> ServerStatus : verwaltet

    %% ============================================================
    %% BEZIEHUNGEN: Service Interfaces
    %% ============================================================

    NetworkService ..|> NetworkServiceProtocol : implementiert
    DependencyContainer --> NetworkServiceProtocol : haelt

    %% ============================================================
    %% BEZIEHUNGEN: Service -> Model
    %% ============================================================

    LocationService --> Location : liefert
    LocationService --> LocationFilter : filtert mit
    FeedService --> FeedResponse : liefert
    CommentService --> Comment : liefert
    FriendshipService --> Friendship : liefert
    FriendshipService --> FriendSuggestion : liefert
    FriendshipService --> User : liefert
    UserService --> User : liefert
    ProfileService --> User : liefert
    AuthService --> User : liefert

    %% ============================================================
    %% BEZIEHUNGEN: Backend Controller -> Service
    %% ============================================================

    LocationController --> NotificationService : nutzt
    CommentController --> NotificationService : nutzt
    FriendshipController --> NotificationService : nutzt
    NotificationService --> APNsService : nutzt

    %% ============================================================
    %% BEZIEHUNGEN: API Response Generics
    %% ============================================================

    FeedResponse --> Location : enthaelt
```
