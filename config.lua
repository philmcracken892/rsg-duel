Config = {}

Config.DuelReward = 50 -- Amount of cash rewarded to winner

-- rsg-duels/locales/en.lua
local Translations = {
    duel = {
        request_sent = 'Duel request sent!',
        request_received = 'You have received a duel request!',
        already_dueling = 'You are already in a duel!',
        no_pending_requests = 'You have no pending duel requests!',
        request_declined = 'Duel request declined!',
        duel_countdown = 'Duel starting in %{time}...',
        fight = 'FIGHT!',
        won_duel = 'You won the duel! You received $%{amount}!',
        lost_duel = 'You lost the duel!',
        duel_request_expired = 'Duel request expired!',
        duel_accepted = 'Duel accepted! Prepare yourself!',
        duel_request_accepted = 'Your duel request was accepted! Prepare yourself!',
        duel_request_declined = 'Your duel request was declined!'
    }
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
