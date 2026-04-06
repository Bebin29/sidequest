# Klassendiagramm - Sidequest

## 1. Kern-Datenmodell

```mermaid
classDiagram
    direction TB

    class User {
        +id : UUID
        +email : String
        +username : String
        +displayName : String
        +profileImageUrl : String
        +bio : String
        +createdAt : Date
        +updatedAt : Date
        +lastSeenAt : Date
        +preferences : JSON
        +favoriteCategories : String[]
        +isVerified : Bool
        +isModerator : Bool
        +isPrivate : Bool
        +fcmToken : String
        +stats : JSON
    }

    class Location {
        +id : UUID
        +name : String
        +address : String
        +latitude : Double
        +longitude : Double
        +geohash : String
        +category : String
        +averageRating : Double
        +totalRatings : Int
        +createdAt : Date
        +createdBy : UUID
        +description : String
        +imageUrls : String[]
        +thumbnailUrl : String
        +tags : String[]
        +priceRange : String
        +noiseLevel : String
        +wifiAvailable : Bool
        +isDogFriendly : Bool
        +isFamilyFriendly : Bool
        +phoneNumber : String
        +website : String
        +instagramHandle : String
        +isVerified : Bool
        +reportCount : Int
        +trendingScore : Double
    }

    class Trip {
        +id : UUID
        +userId : UUID
        +username : String
        +name : String
        +description : String
        +locationCount : Int
        +createdAt : Date
        +startDate : Date
        +endDate : Date
        +coverImageUrl : String
        +isCollaborative : Bool
        +isPublic : Bool
        +viewCount : Int
    }

    class Friendship {
        +id : UUID
        +requesterId : UUID
        +receiverId : UUID
        +status : String
        +createdAt : Date
        +acceptedAt : Date
        +requesterUsername : String
        +receiverUsername : String
    }

    class Notification {
        +id : UUID
        +recipientId : UUID
        +senderId : UUID
        +type : String
        +title : String
        +body : String
        +data : JSON
        +isRead : Bool
        +createdAt : Date
    }

    class Rating {
        +id : UUID
        +locationId : UUID
        +locationName : String
        +userId : UUID
        +username : String
        +rating : Int
        +comment : String
        +imageUrls : String[]
        +createdAt : Date
        +tripId : UUID
        +isVerified : Bool
        +reportCount : Int
        +isHidden : Bool
        +reactionCount : Int
        +helpfulCount : Int
        +visitDate : Date
        +priceSpent : Double
        +wouldRecommend : Bool
    }

    class Comment {
        +id : UUID
        +locationId : UUID
        +userId : UUID
        +username : String
        +text : String
        +createdAt : Date
    }

    class FriendSuggestion {
        +id : UUID
        +username : String
        +displayName : String
        +profileImageUrl : String
        +mutualCount : Int
        +mutualUsernames : String[]
    }

    User "1" --> "*" Location : erstellt
    User "1" --> "*" Trip : besitzt
    User "1" --> "*" Friendship : beteiligt
    User "1" --> "*" Notification : empfaengt

    Location "1" --> "*" Rating : hat
    Location "1" --> "*" Comment : hat
```

## 2. Location-Komposition

```mermaid
classDiagram
    direction TB

    class Location {
        +id : UUID
        +name : String
        +openingHours : OpeningHours
        +parkingInfo : ParkingInfo
        +accessibility : AccessibilityInfo
    }

    class OpeningHours {
        +monday : DayHours
        +tuesday : DayHours
        +wednesday : DayHours
        +thursday : DayHours
        +friday : DayHours
        +saturday : DayHours
        +sunday : DayHours
    }

    class ParkingInfo {
        +hasParking : Bool
        +parkingType : String
        +isFree : Bool
        +notes : String
    }

    class AccessibilityInfo {
        +wheelchairAccessible : Bool
        +hasElevator : Bool
        +hasAccessibleRestroom : Bool
    }

    class DayHours {
        +openTime : String
        +closeTime : String
        +isClosed : Bool
    }

    Location "1" *-- "1" OpeningHours
    Location "1" *-- "1" ParkingInfo
    Location "1" *-- "1" AccessibilityInfo

    OpeningHours "1" *-- "7" DayHours
```

## 3. iOS-Architektur (ViewModels und Services)

```mermaid
classDiagram
    direction LR

    class AuthViewModel {
        +currentUser : User
        +isAuthenticated : Bool
        +needsOnboarding : Bool
        +isLoading : Bool
        +errorMessage : String
        +handleAppleSignIn(result)
        +signIn(appleUserId, email, displayName)
        +checkExistingSession()
        +signOut()
        +deleteAccount()
    }

    class AuthService {
        -session : URLSession
        +signInWithApple(appleUserId, email, displayName) User
    }

    class MapViewModel {
        +locations : Location[]
        +isLoading : Bool
        +filter : LocationFilter
        +loadLocations(userId)
        +addLocation(body)
    }

    class LocationService {
        -session : URLSession
        +getLocation(id) Location
        +fetchLocations(userId, filter) Location[]
        +createLocation(body) Location
        +updateLocation(id, body) Location
        +deleteLocation(id)
    }

    class FeedViewModel {
        +locations : Location[]
        +isLoading : Bool
        +hasMore : Bool
        +currentIndex : Int
        +userLocation : CLLocation
        +fetchLocation()
        +sortByDistance()
        +loadFeed(userId)
        +loadMore(userId)
    }

    class FeedService {
        -session : URLSession
        +fetchFeed(userId, limit, offset) FeedResponse
    }

    class FriendsViewModel {
        +friends : Friendship[]
        +pendingRequests : Friendship[]
        +sentRequests : Friendship[]
        +suggestions : FriendSuggestion[]
        +searchResults : User[]
        +isLoading : Bool
        +loadFriends(userId)
        +searchUsers(query)
        +sendRequest(requesterId, receiverUsername)
        +acceptRequest(friendshipId, userId)
        +declineRequest(friendshipId, userId)
        +removeFriend(friendshipId, userId)
    }

    class FriendshipService {
        -session : URLSession
        +searchUsers(query) User[]
        +sendRequest(requesterId, receiverUsername) Friendship
        +getFriends(userId) Friendship[]
        +getPendingRequests(userId) Friendship[]
        +getSentRequests(userId) Friendship[]
        +updateStatus(friendshipId, status) Friendship
        +getSuggestions(userId) FriendSuggestion[]
        +removeFriend(friendshipId)
    }

    class LocationDetailViewModel {
        +comments : Comment[]
        +isLoading : Bool
        +errorMessage : String
        +loadComments(locationId)
        +addComment(locationId, userId, text)
    }

    class CommentService {
        -session : URLSession
        +fetchComments(locationId) Comment[]
        +createComment(locationId, userId, text) Comment
    }

    class AdminViewModel {
        +users : User[]
        +serverStatus : ServerStatus
        +isLoading : Bool
        +loadAll()
        +loadUsers()
        +loadServerStatus()
    }

    class UserService {
        -session : URLSession
        +fetchUsers() User[]
    }

    AuthViewModel ..> AuthService
    MapViewModel ..> LocationService
    FeedViewModel ..> FeedService
    FriendsViewModel ..> FriendshipService
    LocationDetailViewModel ..> CommentService
    AdminViewModel ..> UserService
```

## 4. Weitere iOS-Services

```mermaid
classDiagram
    direction LR

    class NetworkServiceProtocol {
        <<interface>>
        +request(endpoint, method) T
    }

    class NetworkService {
        -session : URLSession
        +request(endpoint, method) T
    }

    class DependencyContainer {
        +networkService : NetworkServiceProtocol
    }

    class ProfileService {
        -session : URLSession
        +getUser(id) User
        +checkUsername(username) Bool
        +updateProfile(userId, body) User
    }

    class ImageUploadService {
        -session : URLSession
        +upload(image) String
    }

    class PushNotificationService {
        +isAuthorized : Bool
        +deviceToken : String
        +requestAuthorization() Bool
        +uploadToken(userId, token)
    }

    NetworkService ..|> NetworkServiceProtocol : implementiert
    DependencyContainer --> NetworkServiceProtocol
    PushNotificationService ..> ProfileService
```

## 5. Backend-Architektur (Controller und Services)

```mermaid
classDiagram
    direction LR

    class AuthController {
        <<controller>>
        +signInWithApple(req, res)
    }

    class UserController {
        <<controller>>
        +getAll(req, res)
        +getById(req, res, id)
        +create(req, res)
        +update(req, res, id)
        +remove(req, res, id)
        +checkUsername(req, res)
    }

    class LocationController {
        <<controller>>
        +getAll(req, res)
        +getById(req, res, id)
        +create(req, res)
        +update(req, res, id)
        +remove(req, res, id)
        +getFeed(req, res)
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
        +getFriends(req, res, userId)
        +getPendingRequests(req, res, userId)
        +getSentRequests(req, res, userId)
        +updateStatus(req, res, id)
        +remove(req, res, id)
        +searchUsers(req, res)
    }

    class NotificationController {
        <<controller>>
        +getByUser(req, res, userId)
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

    class NotificationService {
        <<service>>
        +createAndSend(options)
        +notifyFriendRequest(senderId, receiverId)
        +notifyFriendAccepted(accepterId, requesterId)
        +notifyNewComment(commenterId, locationId)
        +notifyFriendNewSpot(creatorId, locationName)
    }

    class APNsService {
        <<service>>
        -KEY_ID : String
        -TEAM_ID : String
        -BUNDLE_ID : String
        +isConfigured() Bool
        +getToken() String
        +sendPush(deviceToken, options)
    }

    LocationController ..> NotificationService
    CommentController ..> NotificationService
    FriendshipController ..> NotificationService
    NotificationService ..> APNsService
```

## 6. Monitoring-Struktur

```mermaid
classDiagram
    direction TB

    class ServerStatus {
        +status : String
        +timestamp : String
        +isHealthy() Bool
        +formattedUptime() String
    }

    class ServerInfo {
        +uptimeSeconds : Int
        +nodeVersion : String
    }

    class MemoryInfo {
        +rss : Int
        +heapUsed : Int
        +heapTotal : Int
    }

    class DatabaseInfo {
        +connected : Bool
        +responseMs : Int
        +serverTime : String
    }

    class TableCounts {
        +users : Int
        +locations : Int
        +ratings : Int
        +comments : Int
        +friendships : Int
        +notifications : Int
    }

    ServerStatus "1" *-- "1" ServerInfo
    ServerStatus "1" *-- "1" DatabaseInfo
    ServerStatus "1" *-- "1" TableCounts
    ServerInfo "1" *-- "1" MemoryInfo
```

## 7. API-Antworttypen

```mermaid
classDiagram
    direction LR

    class APIResponse~T~ {
        +data : T
    }

    class APIListResponse~T~ {
        +data : T[]
        +count : Int
    }

    class APIErrorResponse {
        +error : String
    }

    class FeedResponse {
        +data : Location[]
        +count : Int
        +hasMore : Bool
    }

    class LocationFilter {
        +category : String
        +search : String
        +latitude : Double
        +longitude : Double
        +radiusMeters : Double
        +isEmpty() Bool
    }
```
