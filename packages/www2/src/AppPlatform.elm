module AppPlatform exposing (AppModel, ifElectron, isElectron, unlessElectron)


type alias AppModel m f =
    { m | flags : { f | platform : String } }


isElectron : AppModel m f -> Bool
isElectron m =
    "electron" == m.flags.platform


ifElectron : AppModel m f -> a -> a -> a
ifElectron m yes no =
    if isElectron m then
        yes

    else
        no


unlessElectron : AppModel m f -> a -> a -> a
unlessElectron m yes no =
    if not <| isElectron m then
        yes

    else
        no
