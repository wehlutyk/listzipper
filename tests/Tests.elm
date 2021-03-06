module Tests exposing (..)

import Expect
import Fuzz exposing (..)
import List.Zipper exposing (..)
import Test exposing (..)


all : Test
all =
    describe "List.Zipper"
        [ constructing
        , accessors
        , mapping
        , moving
        ]


constructing : Test
constructing =
    describe "Constructing a Zipper"
        [ describe "#singleton"
            [ fuzz int "should result in a zipper focussed on the only element" <|
                \i ->
                    expectZipper [] i [] <| singleton i
            ]
        , describe "#fromLIst"
            [ fuzz (list int) "should maybe return a zipper" <|
                \l ->
                    case l of
                        [] ->
                            Expect.equal Nothing (fromList l)

                        head :: tail ->
                            fromList l
                                |> Expect.equal (Just (Zipper [] head tail))
            ]
        , describe "#withDefault"
            [ test "should provide an alternative when constructing a Zipper fails" <|
                \() ->
                    fromList []
                        |> withDefault 42
                        |> expectZipper [] 42 []
            ]
        ]


accessors : Test
accessors =
    describe "Accessors"
        [ describe "#before"
            [ fuzzZipper "should return the elements before the focussed element" <|
                \z b f a ->
                    Expect.equal (List.reverse b) <| before z
            ]
        , describe "#current"
            [ fuzzZipper "should return the focussed element" <|
                \z b f a ->
                    Expect.equal f <| current z
            ]
        , describe "#after"
            [ fuzzZipper "should return the elements after the focussed element" <|
                \z b f a ->
                    Expect.equal a <| after z
            ]
        , describe "#toList"
            [ fuzzZipper "should return a list of all elements" <|
                \z b f a ->
                    Expect.equal ((List.reverse b) ++ [ f ] ++ a) <| toList z
            ]
        ]


mapping : Test
mapping =
    let
        negtive =
            (*) -1

        negtiveAll =
            List.map negtive
    in
        describe "mapping"
            [ describe "#map"
                [ fuzzZipper "should apply a function to all elements in the `Zipper`" <|
                    \z b f a ->
                        List.Zipper.map negtive z
                            |> expectZipper (negtiveAll b) (negtive f) (negtiveAll a)
                ]
            , describe "#mapBefore"
                [ fuzzZipper "should apply a function to all elements before the focussed element" <|
                    \z b f a ->
                        List.Zipper.mapBefore negtiveAll z
                            |> expectZipper (negtiveAll b) f a
                ]
            , describe "#mapCurrent"
                [ fuzzZipper "should apply a function to the focussed element" <|
                    \z b f a ->
                        List.Zipper.mapCurrent negtive z
                            |> expectZipper b (negtive f) a
                ]
            , describe "#mapAfter"
                [ fuzzZipper "should apply a function to all elements after the focussed element" <|
                    \z b f a ->
                        List.Zipper.mapAfter negtiveAll z
                            |> expectZipper b f (negtiveAll a)
                ]
            ]


moving : Test
moving =
    describe "moving"
        [ describe "#next"
            [ fuzzZipper "should set the focus to the next item" <|
                \z b f a ->
                    next z
                        |> Maybe.map current
                        |> Expect.equal (List.head a)
            ]
        , describe "#previous"
            [ fuzzZipper "should set the focus to the previous item" <|
                \z b f a ->
                    previous z
                        |> Maybe.map current
                        |> Expect.equal (List.head b)
            ]
        , describe "#first"
            [ fuzzZipper "should set the focus to the first item" <|
                \z b f a ->
                    if List.isEmpty b then
                        Expect.equal f <| current <| first z
                    else
                        first z
                            |> current
                            |> Just
                            |> Expect.equal (List.head <| List.reverse b)
            ]
        , describe "#last"
            [ fuzzZipper "should set the focus to the last item" <|
                \z b f a ->
                    if List.isEmpty a then
                        Expect.equal f <| current <| last z
                    else
                        last z
                            |> current
                            |> Just
                            |> Expect.equal (List.head <| List.reverse a)
            ]
        ]


expectZipper : List a -> a -> List a -> Zipper a -> Expect.Expectation
expectZipper b f a z =
    Zipper b f a
        |> Expect.equal z


fuzzZipper : String -> (Zipper Int -> List Int -> Int -> List Int -> Expect.Expectation) -> Test
fuzzZipper title expectation =
    fuzz3 (list int) int (list int) title <|
        \b f a -> expectation (Zipper b f a) b f a
