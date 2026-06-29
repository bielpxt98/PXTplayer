sub init()
    m.poster = m.top.findNode("poster")
    m.posterFallback = m.top.findNode("posterFallback")
    m.titleLabel = m.top.findNode("titleLabel")
    m.metaLabel = m.top.findNode("metaLabel")
    m.descriptionLabel = m.top.findNode("descriptionLabel")
    m.seasonList = m.top.findNode("seasonList")
    m.episodeList = m.top.findNode("episodeList")
    m.episodesTitleLabel = m.top.findNode("episodesTitleLabel")
    m.spinner = m.top.findNode("spinner")
    m.messageLabel = m.top.findNode("messageLabel")
    m.selectedSeries = {}
    m.details = invalid
    m.seasons = []
    m.episodesBySeason = {}
    m.focusArea = "seasons"
end sub

sub onSelectedSeriesChanged()
    m.selectedSeries = m.top.selectedSeries
    m.details = invalid
    renderBasic()
    clearDetails()
end sub

sub onDetailsChanged()
    m.details = m.top.details
    renderAll()
end sub

sub onLoadingChanged()
    m.spinner.visible = m.top.loading
    if m.top.loading then m.spinner.control = "start" else m.spinner.control = "stop"
end sub

sub onMessageChanged()
    m.messageLabel.text = clean(m.top.message, "")
end sub

sub setDetailFocus()
    m.focusArea = "seasons"
    m.seasonList.setFocus(true)
end sub

sub renderBasic()
    info = invalid
    if m.details <> invalid and Type(m.details.info) = "roAssociativeArray" then info = m.details.info
    m.titleLabel.text = clean(pick(info, ["name"], pick(m.selectedSeries, ["name"], "Serie")), "Serie")
    cover = clean(pick(info, ["cover", "movie_image"], pick(m.selectedSeries, ["cover", "stream_icon"], "")), "")
    m.poster.uri = cover
    m.poster.visible = cover <> ""
    m.posterFallback.visible = cover = ""
    rating = clean(pick(info, ["rating", "rating_5based"], "Sem avaliacao"), "Sem avaliacao")
    year = extractYear(clean(pick(info, ["releaseDate", "release_date", "year"], "Ano nao informado"), "Ano nao informado"))
    genre = clean(pick(info, ["genre"], "Genero nao informado"), "Genero nao informado")
    m.metaLabel.text = rating + " • " + year + " • " + genre
    m.descriptionLabel.text = clean(pick(info, ["plot", "description", "overview"], "Descricao nao disponivel."), "Descricao nao disponivel.")
end sub

sub clearDetails()
    m.seasonList.content = CreateObject("roSGNode", "ContentNode")
    m.episodeList.content = CreateObject("roSGNode", "ContentNode")
    m.episodesTitleLabel.text = "EPISODIOS"
end sub

sub renderAll()
    renderBasic()
    buildSeasons()
    renderSeasons()
    selectInitialSeason()
end sub

sub buildSeasons()
    m.seasons = [] : m.episodesBySeason = {}
    if m.details = invalid then return
    eps = m.details.episodes
    if Type(eps) = "roAssociativeArray"
        for each k in eps
            arr = eps[k]
            if Type(arr) = "roArray" then m.episodesBySeason[k] = sortedEpisodes(arr)
        end for
    end if
    if Type(m.details.seasons) = "roArray"
        for each s in m.details.seasons
            num = clean(pick(s, ["season_number"], ""), "")
            if num <> "" then m.seasons.Push({ number: num.ToInt(), key: num, title: seasonTitle(num.ToInt()) })
        end for
    end if
    if m.seasons.Count() = 0
        for each k in m.episodesBySeason
            m.seasons.Push({ number: k.ToInt(), key: k, title: seasonTitle(k.ToInt()) })
        end for
    end if
    m.seasons.SortBy("number", "i")
end sub

sub renderSeasons()
    root = CreateObject("roSGNode", "ContentNode")
    for each s in m.seasons
        n = root.createChild("ContentNode") : n.title = s.title : n.seasonKey = s.key
    end for
    m.seasonList.content = root
end sub

sub selectInitialSeason()
    idx = 0
    for i = 0 to m.seasons.Count() - 1
        if m.seasons[i].number = 1 then idx = i : exit for
    end for
    m.seasonList.jumpToItem = idx
    renderEpisodes(idx)
end sub

sub renderEpisodes(seasonIndex as integer)
    if seasonIndex < 0 or seasonIndex >= m.seasons.Count() then return
    season = m.seasons[seasonIndex]
    m.episodesTitleLabel.text = "EPISODIOS — " + season.title
    root = CreateObject("roSGNode", "ContentNode")
    eps = [] : if m.episodesBySeason.DoesExist(season.key) then eps = m.episodesBySeason[season.key]
    for each e in eps
        num = clean(pick(e, ["episode_num"], ""), "")
        if num = "" then num = clean(pick(e, ["id", "stream_id"], ""), "")
        title = clean(pick(e, ["title"], ""), "")
        if title = "" then title = "Episodio " + num
        n = root.createChild("ContentNode") : n.title = "E" + pad2(num) + " — " + title
    end for
    m.episodeList.content = root
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "back"
        if m.focusArea = "episodes" then m.focusArea = "seasons" : m.seasonList.setFocus(true) else m.top.backRequested = true
        return true
    end if
    if m.focusArea = "seasons"
        if key = "left" or key = "right"
            idx = m.seasonList.itemFocused
            if key = "left" and idx > 0 then idx = idx - 1
            if key = "right" and idx < m.seasons.Count() - 1 then idx = idx + 1
            m.seasonList.jumpToItem = idx
            renderEpisodes(idx)
            return true
        end if
        if key = "down" then m.focusArea = "episodes" : m.episodeList.setFocus(true) : return true
        if key = "OK" then return true
    else if m.focusArea = "episodes"
        if key = "up" and m.episodeList.itemFocused <= 0 then m.focusArea = "seasons" : m.seasonList.setFocus(true) : return true
        if key = "OK" then return true
    end if
    return false
end function

function sortedEpisodes(arr as object) as object
    out = []
    for each e in arr
        e.sort_num = clean(pick(e, ["episode_num"], "0"), "0").ToInt()
        out.Push(e)
    end for
    out.SortBy("sort_num", "i")
    return out
end function

function seasonTitle(n as integer) as string
    if n = 0 then return "ESPECIAIS"
    return "T" + n.ToStr()
end function

function pad2(v as dynamic) as string
    s = clean(v, "1")
    if s.ToInt() < 10 then return "0" + s.ToInt().ToStr()
    return s.ToInt().ToStr()
end function

function extractYear(s as string) as string
    if s.Len() >= 4 then return s.Left(4)
    return s
end function

function pick(aa as dynamic, keys as object, fallback as dynamic) as dynamic
    if Type(aa) = "roAssociativeArray"
        for each k in keys
            if aa.DoesExist(k) and clean(aa[k], "") <> "" then return aa[k]
        end for
    end if
    return fallback
end function

function clean(v as dynamic, fallback as string) as string
    if v = invalid then return fallback
    s = v.ToStr().Trim()
    l = LCase(s)
    if s = "" or l = "null" or l = "invalid" or l = "undefined" then return fallback
    return s
end function
