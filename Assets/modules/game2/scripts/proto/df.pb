
�$
game_mahjong.protomahjong"(
GameMessage
Ops (
Data ("U
MsgMeldTile
meldType (
tile1 (
contributor (
chowTile ("�
MsgPlayerTileList
chairID (
tileCountInHand (
	tilesHand (
tilesFlower (
tilesDiscard (#
melds (2.mahjong.MsgMeldTile"�
MsgDeal
bankerChairID (
windFlowerID (3
playerTileLists (2.mahjong.MsgPlayerTileList
tilesInWall (
dice1 (
dice2 (
isContinuousBanker (
markup ("=
MsgReadyHandTips

targetTile (
readyHandList ("�
MsgAllowPlayerAction
qaIndex (
actionChairID (
allowedActions (
timeoutInSeconds (0
tipsForAction (2.mahjong.MsgReadyHandTips,
meldsForAction (2.mahjong.MsgMeldTile"�
MsgAllowPlayerReAction
qaIndex (
actionChairID (
allowedActions (
timeoutInSeconds (,
meldsForAction (2.mahjong.MsgMeldTile
victimTileID (
victimChairID ("t
MsgPlayerAction
qaIndex (
action (
flags (
tile (
meldType (
	meldTile1 ("�
MsgActionResultNotify
targetChairID (
action (

actionTile ((

actionMeld (2.mahjong.MsgMeldTile

newFlowers (
tilesInWall (
waitDiscardReAction ("�

MsgRestore!
msgDeal (2.mahjong.MsgDeal
readyHandChairs (
lastDiscaredChairID (
isMeNewDraw (
waitDiscardReAction (
flyReadyHandChairs (
extra ("�
MsgPlayerScoreGreatWin
baseWinScore (
greatWinType (
greatWinPoints (
trimGreatWinPoints (
continuousBankerExtra ("�
MsgPlayerScoreMiniWin
miniWinType (
miniWinBasicScore (
miniWinFlowerScore (
miniMultiple (
miniWinTrimScore (
continuousBankerExtra ("�
MsgPlayerScore
targetChairID (
winType (
score (
specialScore (1
greatWin (2.mahjong.MsgPlayerScoreGreatWin/
miniWin (2.mahjong.MsgPlayerScoreMiniWin
fakeWinScore (
fakeList (
isContinuousBanker	 ( 
continuousBankerMultiple
 ("=
MsgHandScore-
playerScores (2.mahjong.MsgPlayerScore"�
MsgHandOver
endType (3
playerTileLists (2.mahjong.MsgPlayerTileList%
scores (2.mahjong.MsgHandScore
continueAble ("5
MsgUpdateLocation
userID (	
location (	"#
MsgUpdatePropCfg
propCfg (	*�
TileID
enumTid_MAN1 
enumTid_MAN2
enumTid_MAN3
enumTid_MAN4
enumTid_MAN5
enumTid_MAN6
enumTid_MAN7
enumTid_MAN8
enumTid_MAN9
enumTid_PIN1	
enumTid_PIN2

enumTid_PIN3
enumTid_PIN4
enumTid_PIN5
enumTid_PIN6
enumTid_PIN7
enumTid_PIN8
enumTid_PIN9
enumTid_SOU1
enumTid_SOU2
enumTid_SOU3
enumTid_SOU4
enumTid_SOU5
enumTid_SOU6
enumTid_SOU7
enumTid_SOU8
enumTid_SOU9
enumTid_TON
enumTid_NAN
enumTid_SHA
enumTid_PEI
enumTid_HAK
enumTid_HAT 
enumTid_CHU!
enumTid_PLUM"
enumTid_ORCHID#
enumTid_BAMBOO$
enumTid_CHRYSANTHEMUM%
enumTid_SPRING&
enumTid_SUMMER'
enumTid_AUTUMN(
enumTid_WINTER)
enumTid_MAX**�
MessageCode
	OPInvalid 
OPAction
OPActionResultNotify
OPActionAllowed
OPReActionAllowed

OPDeal

OPHandOver
	OPRestore
OPPlayerLeaveRoom	
OPPlayerEnterRoom

OPDisbandRequest
OPDisbandNotify
OPDisbandAnswer
OPPlayerReady
OPRoomDeleted
OPRoomUpdate
OPRoomShowTips

OPGameOver
	OPKickout
OPDonate
OPUpdateLocation
OP2Lobby
OPUpdatePropCfg*�
MeldType
enumMeldTypeSequence 
enumMeldTypeTriplet
enumMeldTypeExposedKong
enumMeldTypeTriplet2Kong
enumMeldTypeConcealedKong
enumMeldTypeSelfMeld
enumMeldTypeChuHH
enumMeldTypeChuHH1
enumMeldTypeWind
enumMeldTypePairKong	*�

ActionType
enumActionType_SKIP
enumActionType_DISCARD
enumActionType_DRAW
enumActionType_CHOW
enumActionType_PONG
enumActionType_KONG_Exposed !
enumActionType_KONG_Concealed@
enumActionType_WIN_Chuck�!
enumActionType_WIN_SelfDrawn�!
enumActionType_KONG_Triplet2�"
enumActionType_FirstReadyHand�
enumActionType_ReadyHand�
enumActionType_CustomA� 
enumActionType_CustomB�@
enumActionType_CustomC��
enumActionType_CustomD��*�
HandOverType
enumHandOverType_None "
enumHandOverType_Win_SelfDrawn
enumHandOverType_Win_Chuck
enumHandOverType_Chucker
enumHandOverType_Konger 
enumHandOverType_Win_RobKong
�
game_mahjong_replay.protomahjong"�
MsgReplayPlayerInfo
userID (	
nick (	
chairID (

totalScore (
sex (
headIconURI (	
avatarID ("N
MsgReplayPlayerScoreSummary
chairID (
score (
winType ("�
MsgReplayRecordSummary

recordUUID (	:
playerScores (2$.mahjong.MsgReplayPlayerScoreSummary
endTime (
shareAbleID (	
	startTime ("�
MsgReplayRoom
recordRoomType (
	startTime (
endTime (

roomNumber (	-
players (2.mahjong.MsgReplayPlayerInfo0
records (2.mahjong.MsgReplayRecordSummary
ownerUserID (	
�	
game_mahjong_df.proto	dfmahjong*�
GreatWinType
enumGreatWinType_None !
enumGreatWinType_ChowPongKong
enumGreatWinType_FinalDraw
enumGreatWinType_PongKong
enumGreatWinType_PureSame
enumGreatWinType_MixedSame
enumGreatWinType_ClearFront 
enumGreatWinType_SevenPair@$
enumGreatWinType_GreatSevenPair�
enumGreatWinType_Heaven�(
#enumGreatWinType_AfterConcealedKong�&
!enumGreatWinType_AfterExposedKong�
enumGreatWinType_Richi�.
)enumGreatWinType_PongKongWithFlowerNoMeld� .
)enumGreatWinType_PureSameWithFlowerNoMeld�@.
(enumGreatWinType_MixSameWithFlowerNoMeld��'
!enumGreatWinType_PureSameWithMeld��&
 enumGreatWinType_MixSameWithMeld��
enumGreatWinType_RobKong��%
enumGreatWinType_OpponentsRichi��*�
MiniWinType
enumMiniWinType_None %
!enumMiniWinType_Continuous_Banker
enumMiniWinType_SelfDraw
enumMiniWinType_NoFlowers 
enumMiniWinType_Kong2Discard!
enumMiniWinType_Kong2SelfDraw$
 enumMiniWinType_SecondFrontClear !
enumMiniWinType_PongSelfDrawn@!
enumMiniWinType_ChowPongkong�
enumMiniWinType_Richi�
enumMiniWinType_SevenPair�%
 enumMiniWinType_PureSameWithMeld�$
enumMiniWinType_MixSameWithMeld�
�
game_mahjong_s2s.protomahjong"t
SRMsgPlayerInfo
userID (	
chairID (
nick (	
sex (
headIconURI (	
avatarID ("G
SRDealDetail
chairID (
	tilesHand (
tilesFlower ("p
SRAction
action (
chairID (
qaIndex (
tiles (
flags (
allowActions ("=
SRMsgHandRecorderExtra
markup (
ownerUserID (	"�
SRMsgHandRecorder
bankerChairID (
windFlowerID ()
players (2.mahjong.SRMsgPlayerInfo

isHandOver ($
deals (2.mahjong.SRDealDetail"
actions (2.mahjong.SRAction
	handScore (
roomConfigID (	
	startTime	 (
endTime
 (
handNum (
isContinuousBanker (

roomNumber (	
roomType (.
extra (2.mahjong.SRMsgHandRecorderExtra*G
SRFlags

SRNone 
SRUserReplyOnly
SRRichi

SRFlyRichi
�
game_mahjong_split2.protomahjong"�
MsgPlayerInfo
userID (	
chairID (
state (
name (	
nick (	
sex (
headIconURI (	

ip (	
location	 (	
dfHands
 (
diamond (
charm (
avatarID (
clubIDs (	
dan ("G
PlayerHandScoreRecord
userID (	
winType (
score ("s
MsgRoomHandScoreRecord
endType (
	handIndex (5
playerRecords (2.mahjong.PlayerHandScoreRecord"�
MsgRoomInfo
state ('
players (2.mahjong.MsgPlayerInfo
ownerID (	

roomNumber (	
handStartted (5
scoreRecords (2.mahjong.MsgRoomHandScoreRecord
handFinished ("I
RoomScoreRecords5
scoreRecords (2.mahjong.MsgRoomHandScoreRecord"!
MsgDisbandAnswer
agree ("~
MsgDisbandNotify
disbandState (
	applicant (
waits (
agrees (
rejects (
	countdown ("�
MsgGameOverPlayerStat
chairID (
score (
winChuckCounter (
winSelfDrawnCounter (
chuckerCounter (
robKongCounter (
kongerCounter ("B
MsgGameOver3
playerStats (2.mahjong.MsgGameOverPlayerStat"0
MsgRoomShowTips
tips (	
tipCode ("
MsgRoomDelete
reason (""

MsgKickout
victimUserID (	"t
MsgKickoutResult
result (
victimUserID (	

victimNick (	
	byWhoNick (	
byWhoUserID (	"$
MsgEnterRoomResult
status ("C
	MsgDonate
	toChairID (
itemID (
fromChairID (*P
	RoomState
	SRoomIdle 
SRoomWaiting
SRoomPlaying
SRoomDeleted*D
PlayerState

PSNone 
PSReady
	PSOffline
	PSPlaying*�
DisbandState
Waiting
Done
DoneWithOtherReject!
DoneWithRoomServerNotResponse
DoneWithWaitReplyTimeout
ErrorDuplicateAcquire"
ErrorNeedOwnerWhenGameNotStart*S
TipCode

TCNone 
TCWaitOpponentsAction!
TCDonateFailedNoEnoughDiamond*�
RoomDeleteReason
IdleTimeout
DisbandByOwnerFromRMS
DisbandByApplication
DisbandBySystem
DisbandMaxHand
DisbandInLoseProtected*�
KickoutResult
KickoutResult_Success'
#KickoutResult_FailedGameHasStartted!
KickoutResult_FailedNeedOwner&
"KickoutResult_FailedPlayerNotExist*�
EnterRoomStatus
Success 
RoomNotExist
RoomIsFulled
RoomPlaying
InAnotherRoom
MonkeyRoomUserIDNotMatch"
MonkeyRoomUserLoginSeqNotMatch
AppModuleNeedUpgrade
InRoomBlackList!
TakeoffDiamondFailedNotEnough	
TakeoffDiamondFailedIO

ParseTokenError
RoomInApplicateDisband
NotClubMember