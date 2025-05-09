# Types

### AccessoryInfo

```luau
AccessoryInfo: {
    name: string,
    assetId: number,
}
```
`name`: The accessories name\
`assetId`: The accessories asset id distributed on roblox marketplace

### FlaggedItem

```luau
FlaggedItem: {
    item: @AccessoryInfo,
    pattern: string,
    score: number
}
```
`item`: An `AccessoryInfo` describing the flagged item\
`pattern`: The flagged sub-string of the item name\
`score`: The score of the item according to the `pattern`

### UserResult

```luau
UserResult: {
    userId: number,
    score: number,
    flaggedItems: {@FlaggedItem}
}
```
`userId`: A user id of the describing player\
`score`: The total score of all the flagged items of the players avatar\
`flaggedItems`: A table containing all flagged items the user is wearing on their avatar

### MultiUserResult

```luau
MultiUserResult: {
    success: boolean,
    users: {@UserResult}?,
    totalScore: number?,
    message: string?
}
```
`success`: Flags whether or not the user fetchs was succesful\
`users`: A list of `UserResult`s of the users, *if the fetch didn't fail*\
`totalScore`: The total score of all the users from the fetch, *if the fetch didn't fail*\
`message`: An error message if the fetch has failed\
<sub>- The so called "fetch" is performed to get patterns from the github patterns json that can be found [here](https://github.com/DevKrazes/RBXLSCORE/blob/main/patterns.json), this includes error cases since this type is exposed in the api</sub>

### SingleUserResult

```luau
SingleUserResult: {
    success: boolean,
    userId: number?,
    score: number?,
    flaggedItems: {@FlaggedItem}?,
    message: string?
}
```
`success`: Flags whether or not the user fetch was succesful\
`userId`: A user id of the describing player, *if the fetch didn't fail*\
`score`: The total score of all the flagged items, *if the fetch didn't fail*\
`flaggedItems`: A table containing all flagged items the user is wearing on their avatar, *if the fetch didn't fail*\
`message`: An error message if the fetch has failed\
<sub>- This is used in the api instead of `UserResult` due to it being unreliable to flag HTTP request fails</sub>

### PatternModifyResult
```luau
PatternModifyResult: {
    success: boolean,
    message: string?
}
```
`success`: A flag denoting if the modification was successful\
`message`: An error message if the request has failed

### Pattern

```luau
Pattern: {
    pattern: string,
    points: number
}
```
`pattern`: A string that is to be matched\
`points`: The score this pattern will give if it is matched

### PatternData

```luau
PatternData: {
    whiteList: {string},
    blackList: {Pattern}
}
```
`whiteList`: A list of white listed pattern match strings\
`blackList`: A list of black listed `Pattern`s
