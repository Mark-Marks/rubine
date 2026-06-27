-- TODO: Move this to const once pesde & wally-package-types support const
local rubine = require("@self/rubine")

export type Scheduler = rubine.Scheduler
export type it<QueryTerms... = (), Singletons... = ()> = rubine.it<
    QueryTerms...,
    Singletons...
>
export type FrameData = rubine.FrameData
export type Phase = rubine.Phase
export type Pipeline = rubine.Pipeline
export type Stepper = rubine.Stepper

return rubine
