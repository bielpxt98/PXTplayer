sub init()
    m.loginScreen = m.top.findNode("loginScreen")
    m.seriesCatalogScreen = m.top.findNode("seriesCatalogScreen")
    m.xtreamService = m.top.findNode("xtreamService")
    m.catalogTimeoutTimer = m.top.findNode("catalogTimeoutTimer")
    m.seriesDetailScreen = m.top.findNode("seriesDetailScreen")
    m.seriesDetailTimeoutTimer = m.top.findNode("seriesDetailTimeoutTimer")

    m.loginScreen.observeField("submit", "onLoginSubmit")
    m.loginScreen.observeField("backRequested", "onLoginBackRequested")
    m.seriesCatalogScreen.observeField("categorySelected", "onCategorySelected")
    m.seriesCatalogScreen.observeField("backRequested", "onCatalogBackRequested")
    m.seriesCatalogScreen.observeField("seriesSelected", "onSeriesSelected")
    m.seriesDetailScreen.observeField("backRequested", "onDetailBackRequested")
    m.xtreamService.observeField("result", "onXtreamResult")
    m.catalogTimeoutTimer.observeField("fire", "onCatalogTimeout")
    m.seriesDetailTimeoutTimer.observeField("fire", "onSeriesDetailTimeout")

    m.connecting = false
    m.catalogLoading = false
    m.detailLoading = false
    m.selectedSeries = invalid
    m.credentials = invalid

    m.loginScreen.account = LoadPlaylistAccount()
    showLogin()
end sub

sub showLogin()
    m.seriesDetailScreen.visible = false
    m.seriesCatalogScreen.visible = false
    m.loginScreen.visible = true
    m.loginScreen.setFocus(true)
end sub

sub showCatalog()
    m.loginScreen.visible = false
    m.seriesDetailScreen.visible = false
    m.seriesCatalogScreen.visible = true
    m.seriesCatalogScreen.callFunc("setCatalogFocus")
end sub

sub onLoginSubmit(event as object)
    PRINT "LOGIN_SUBMIT_RECEIVED"
    if m.connecting then return

    credentials = event.getData()
    dns = NormalizeDns(credentials.dns)
    username = PxtTrim(credentials.username)
    password = PxtTrim(credentials.password)

    if dns = "" or username = "" or password = ""
        m.loginScreen.message = "Preencha DNS, usuário e senha."
        return
    end if

    m.connecting = true
    m.loginScreen.loading = true
    m.loginScreen.message = "Conectando..."
    PRINT "XTREAM_CONNECT_STARTED"
    m.xtreamService.callFunc("connect", { dns: dns, username: username, password: password })
end sub

sub onXtreamResult(event as object)
    result = event.getData()
    if result = invalid then return

    if result.action = "connect"
        m.connecting = false
        m.loginScreen.loading = false

        if result.success = true
            m.credentials = result.account
            SavePlaylistAccount(m.credentials.dns, m.credentials.username, m.credentials.password)
            m.loginScreen.message = ""
            m.seriesCatalogScreen.account = m.credentials
            showCatalog()
            PRINT "SERIES_SCREEN_OPENED"
            loadCategories()
        else
            if result.message <> invalid then m.loginScreen.message = result.message else m.loginScreen.message = "Não foi possível conectar ao servidor."
            showLogin()
        end if
    else if result.action = "get_series_categories"
        PRINT "GET_SERIES_CATEGORIES_RESULT_RECEIVED"
        m.catalogLoading = false
        m.catalogTimeoutTimer.control = "stop"
        m.seriesCatalogScreen.loading = false
        if result.success = true
            PRINT "GET_SERIES_CATEGORIES_SUCCESS"
            m.seriesCatalogScreen.categories = result.categories
            m.seriesCatalogScreen.message = "Selecione uma categoria e pressione OK."
        else
            PRINT "GET_SERIES_CATEGORIES_ERROR"
            if result.code = "timeout"
                m.seriesCatalogScreen.message = "Tempo de conexao esgotado."
            else
                m.seriesCatalogScreen.message = "Nao foi possivel carregar as categorias."
            end if
        end if
    else if result.action = "get_series"
        m.catalogLoading = false
        m.seriesCatalogScreen.loading = false
        if result.success = true
            m.seriesCatalogScreen.series = result.series
            m.seriesCatalogScreen.message = ""
        else
            m.seriesCatalogScreen.message = result.message
        end if
    else if result.action = "get_series_info"
        m.detailLoading = false
        m.seriesDetailTimeoutTimer.control = "stop"
        m.seriesDetailScreen.loading = false
        if result.success = true
            m.seriesDetailScreen.details = result.details
            m.seriesDetailScreen.message = ""
        else
            if result.code = "timeout"
                m.seriesDetailScreen.message = "Tempo de conexao esgotado ao carregar os detalhes."
            else if result.code = "invalid_response" or result.code = "invalid_json"
                m.seriesDetailScreen.message = "O servidor retornou detalhes invalidos."
            else
                m.seriesDetailScreen.message = "Nao foi possivel carregar os detalhes da serie."
            end if
        end if
    end if
end sub

sub loadCategories()
    if m.credentials = invalid or PxtTrim(m.credentials.dns) = "" or PxtTrim(m.credentials.username) = "" or PxtTrim(m.credentials.password) = ""
        m.catalogLoading = false
        m.seriesCatalogScreen.loading = false
        m.seriesCatalogScreen.message = "Conta nao encontrada para carregar categorias."
        return
    end if

    PRINT "ACCOUNT_RECEIVED_BY_SERIES_SCREEN"
    m.catalogLoading = true
    m.seriesCatalogScreen.loading = true
    m.seriesCatalogScreen.message = "Carregando categorias..."
    m.catalogTimeoutTimer.control = "stop"
    m.catalogTimeoutTimer.control = "start"
    PRINT "GET_SERIES_CATEGORIES_STARTED"
    m.xtreamService.callFunc("getSeriesCategories", m.credentials)
end sub

sub onCatalogTimeout()
    if m.catalogLoading
        m.catalogLoading = false
        m.seriesCatalogScreen.loading = false
        m.seriesCatalogScreen.message = "Tempo de conexao esgotado."
        PRINT "GET_SERIES_CATEGORIES_ERROR"
    end if
end sub

sub onCategorySelected(event as object)
    if m.catalogLoading then return
    cat = event.getData()
    m.catalogLoading = true
    m.seriesCatalogScreen.loading = true
    m.seriesCatalogScreen.message = "Carregando series..."
    m.xtreamService.callFunc("getSeries", { account: m.credentials, category_id: cat.category_id })
end sub

sub onLoginBackRequested()
    if m.connecting then return
    m.top.getScene().close = true
end sub

sub onCatalogBackRequested()
    m.catalogLoading = false
    m.catalogTimeoutTimer.control = "stop"
    showLogin()
end sub


sub onSeriesSelected(event as object)
    if m.catalogLoading or m.detailLoading then return
    selected = event.getData()
    if selected = invalid or PxtTrim(selected.series_id) = ""
        m.seriesCatalogScreen.message = "Esta serie nao possui detalhes disponiveis."
        return
    end if
    m.selectedSeries = selected
    m.seriesCatalogScreen.visible = false
    m.seriesDetailScreen.visible = true
    m.seriesDetailScreen.selectedSeries = selected
    m.seriesDetailScreen.loading = true
    m.seriesDetailScreen.message = "Carregando detalhes..."
    m.seriesDetailScreen.callFunc("setDetailFocus")
    m.detailLoading = true
    m.seriesDetailTimeoutTimer.control = "stop"
    m.seriesDetailTimeoutTimer.control = "start"
    m.xtreamService.callFunc("getSeriesInfo", { account: m.credentials, series_id: selected.series_id })
end sub

sub onSeriesDetailTimeout()
    if m.detailLoading
        m.detailLoading = false
        m.seriesDetailScreen.loading = false
        m.seriesDetailScreen.message = "Tempo de conexao esgotado ao carregar os detalhes."
    end if
end sub

sub onDetailBackRequested()
    m.detailLoading = false
    m.seriesDetailTimeoutTimer.control = "stop"
    showCatalog()
end sub
