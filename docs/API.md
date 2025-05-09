# Properties

### fetchedPatterns
```ts
fetchedPatterns: @PatternData?
```
Stores the fetched patterns from github so that they are only fetched once.

# Functions

### getUserAccessories
```ts
getUserAccessories: (userId: number) -> ({@AccessoryInfo})
```
Retrieves all the accessories of a user, including shirts, pants, and any other assets that are currently worn.\
`@param:userId`: The user ID of the player whose accessories are being retrieved\
`@returns:accessories`: A table containing the names and asset IDs of the user's accessories

### CheckUserIds

```ts
CheckUserIds: (userIds: {number}) -> (@MultiUserResult)
```
Check the accessories of multiple users for flagged patterns, determining the appropriateness of each avatar.
The server evaluates the avatars based on a point-based system, returning the results for each user in a table format.\
`@param:userIds`: A list of user IDs to be evaluated\
`@returns:MultiUserResult`: Contains the evaluation results of the avatars

### CheckUserId
```ts
CheckUserId: (userId: number) -> (@SingleUserResult)
```
Check the user's accessories for flagged patterns, determining the appropriateness of the avatar.
The server evaluates the avatar based on a point-based system and returns the result in table format.\
`@param:userId`: The user ID of the player being evaluated\
`@returns:SingleUserResult`: Contains the evaluation results of the avatar

### modifyPattern
```ts
modifyPattern: (listType: string, pattern: string, points: number?) -> (@PatternModifyResult)
```
Adds new patterns in the whiteList or blackList.
This allows you to dynamically modify the patterns used for evaluation.\
`@param:listType`: The list type, either "whiteList" or "blackList"\
`@param:pattern`: The new pattern to add or replace in the list\
`@param:points`: Used for blackList pattern to evaluate total score\
`@returns:PatternModifyResult`: Contains the result of the pattern modification attempt