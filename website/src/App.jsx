import { useEffect, useState } from 'react'
import {
  Anchor,
  ArrowDownToLine,
  ArrowRight,
  BellRing,
  CalendarDays,
  Check,
  ChevronDown,
  Clock3,
  CloudOff,
  Compass,
  History,
  MapPin,
  MapPinned,
  Menu,
  MessageCircle,
  Navigation,
  Radio,
  Route,
  Satellite,
  Search,
  Ship,
  ShieldCheck,
  Smartphone,
  UsersRound,
  Waves,
  X,
} from 'lucide-react'

const APK_PATH = '/downloads/amazon-track.apk'

const features = [
  {
    icon: MapPinned,
    title: 'Localização em tempo real',
    text: 'Visualize no mapa onde a embarcação está e acompanhe todo o trajeto.',
    color: 'green',
  },
  {
    icon: BellRing,
    title: 'Alertas de chegada',
    text: 'Receba uma notificação quando a embarcação se aproximar do porto.',
    color: 'orange',
  },
  {
    icon: CloudOff,
    title: 'Funciona offline',
    text: 'O trajeto continua sendo registrado e sincroniza quando a conexão voltar.',
    color: 'blue',
  },
  {
    icon: CalendarDays,
    title: 'Viagens organizadas',
    text: 'Consulte calendários, rotas, paradas e o histórico das suas viagens.',
    color: 'purple',
  },
  {
    icon: MessageCircle,
    title: 'Contato direto',
    text: 'Passageiros e barqueiros conversam pelo app antes e durante a viagem.',
    color: 'teal',
  },
  {
    icon: ShieldCheck,
    title: 'Mais previsibilidade',
    text: 'Informação clara para planejar o embarque e navegar com tranquilidade.',
    color: 'sand',
  },
]

const profileContent = {
  passenger: {
    eyebrow: 'Para passageiros',
    title: 'Sua viagem começa antes do embarque.',
    description:
      'Encontre embarcações, acompanhe o deslocamento pelo mapa e chegue ao porto no momento certo.',
    bullets: [
      'Busque por embarcação, rota ou cidade',
      'Acompanhe a posição e a velocidade',
      'Receba alertas de aproximação',
      'Consulte calendário e histórico',
    ],
  },
  boatman: {
    eyebrow: 'Para barqueiros',
    title: 'Sua rota visível, sua operação mais simples.',
    description:
      'Compartilhe a posição da embarcação, organize viagens e mantenha os passageiros informados.',
    bullets: [
      'Cadastre embarcações, rotas e paradas',
      'Rastreie mesmo com conexão instável',
      'Organize datas e horários de saída',
      'Converse diretamente com passageiros',
    ],
  },
}

const faqItems = [
  {
    question: 'O aplicativo funciona sem internet?',
    answer:
      'Sim. Durante períodos sem conexão, o Amazon Track mantém os pontos do trajeto salvos no aparelho e sincroniza os dados quando a internet volta.',
  },
  {
    question: 'Quem pode usar o Amazon Track?',
    answer:
      'O app possui experiências específicas para passageiros e barqueiros. No cadastro, você escolhe o perfil adequado para acessar as ferramentas certas.',
  },
  {
    question: 'Como instalar o APK?',
    answer:
      'Toque em “Baixar para Android”, abra o arquivo baixado e autorize a instalação pelo navegador, caso o Android solicite. O arquivo é instalado diretamente no aparelho.',
  },
]

function Brand({ light = false }) {
  return (
    <a className={`brand ${light ? 'brand--light' : ''}`} href="#inicio" aria-label="Amazon Track - Início">
      <span className="brand__mark">
        <MapPin size={19} strokeWidth={2.8} />
        <Waves className="brand__wave" size={20} strokeWidth={2.5} />
      </span>
      <span>
        Amazon <strong>Track</strong>
      </span>
    </a>
  )
}

function DownloadButton({ light = false, compact = false }) {
  return (
    <a
      className={`download-button ${light ? 'download-button--light' : ''} ${compact ? 'download-button--compact' : ''}`}
      href={APK_PATH}
      download="amazon-track.apk"
    >
      <ArrowDownToLine size={compact ? 17 : 19} />
      Baixar para Android
    </a>
  )
}

function MapVisual() {
  return (
    <div className="map-visual" aria-hidden="true">
      <div className="map-road map-road--one" />
      <div className="map-road map-road--two" />
      <div className="map-river">
        <span />
      </div>
      <div className="map-place map-place--one">Porto de Manaus</div>
      <div className="map-place map-place--two">Careiro</div>
      <div className="map-pin map-pin--start">
        <Anchor size={14} />
      </div>
      <div className="map-pin map-pin--end">
        <MapPin size={15} />
      </div>
      <div className="boat-pulse">
        <span className="boat-pulse__ring" />
        <span className="boat-pulse__core">
          <Navigation size={14} fill="currentColor" />
        </span>
      </div>
    </div>
  )
}

function PhoneDemo({ screen }) {
  return (
    <div className="phone-wrap">
      <div className="phone-orbit phone-orbit--one" />
      <div className="phone-orbit phone-orbit--two" />
      <div className="phone">
        <div className="phone__speaker" />
        <div className="phone__screen">
          <div className="phone__status">
            <span>9:41</span>
            <span className="phone__status-icons">
              <Radio size={11} />
              <span className="battery" />
            </span>
          </div>

          <div className="phone__appbar">
            <span>{screen === 0 ? 'Mapa' : screen === 1 ? 'Embarcações' : 'Calendário'}</span>
            <span className="avatar">JM</span>
          </div>

          <div className="phone__content">
            {screen === 0 && (
              <div className="screen-panel screen-panel--map">
                <MapVisual />
                <div className="trip-card">
                  <div className="trip-card__top">
                      <span className="trip-card__boat"><Ship size={17} /></span>
                    <span>
                      <strong>Expresso do Rio</strong>
                      <small>Em viagem agora</small>
                    </span>
                    <span className="live-dot">AO VIVO</span>
                  </div>
                  <div className="trip-card__route">
                    <span>Manaus</span>
                    <span className="route-line"><i /></span>
                    <span>Careiro</span>
                  </div>
                  <div className="trip-card__stats">
                    <span><Clock3 size={12} /> 1h 20min</span>
                    <span><Compass size={12} /> 18 km/h</span>
                  </div>
                </div>
              </div>
            )}

            {screen === 1 && (
              <div className="screen-panel boats-screen">
                <div className="search-bar"><Search size={13} /> Buscar embarcação ou rota</div>
                <div className="filter-row">
                  <span className="active">Todos</span><span>Em viagem</span><span>Disponível</span>
                </div>
                {[
                  ['Expresso do Rio', 'Manaus → Careiro', 'Em viagem'],
                  ['Navegante I', 'Manacapuru → Manaus', 'Disponível'],
                  ['Estrela d’Água', 'Iranduba → Manaus', 'Em viagem'],
                ].map(([name, routeName, status]) => (
                  <div className="boat-row" key={name}>
                    <span className="boat-row__icon"><Ship size={18} /></span>
                    <span className="boat-row__copy"><strong>{name}</strong><small>{routeName}</small></span>
                    <span className={status === 'Em viagem' ? 'status-live' : 'status-free'}>{status}</span>
                  </div>
                ))}
              </div>
            )}

            {screen === 2 && (
              <div className="screen-panel calendar-screen">
                <div className="calendar-title"><strong>Julho 2026</strong><span>‹ &nbsp; ›</span></div>
                <div className="calendar-grid">
                  {['D', 'S', 'T', 'Q', 'Q', 'S', 'S'].map((day, index) => <b key={`${day}-${index}`}>{day}</b>)}
                  {[12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27].map((day) => (
                    <span className={day === 16 ? 'today' : day === 20 || day === 24 ? 'has-trip' : ''} key={day}>{day}</span>
                  ))}
                </div>
                <p className="next-trip-label">Próximas viagens</p>
                <div className="calendar-trip">
                  <span className="date-card"><b>20</b><small>JUL</small></span>
                  <span><strong>Manaus → Careiro</strong><small>08:30 · Expresso do Rio</small></span>
                </div>
                <div className="calendar-trip">
                  <span className="date-card date-card--orange"><b>24</b><small>JUL</small></span>
                  <span><strong>Manaus → Iranduba</strong><small>14:00 · Estrela d’Água</small></span>
                </div>
              </div>
            )}
          </div>

          <div className="phone__nav">
            {[
              [MapPinned, 'Mapa'],
              [Ship, 'Barcos'],
              [CalendarDays, 'Agenda'],
              [History, 'Histórico'],
            ].map(([Icon, label], index) => (
              <span className={screen === index || (screen === 2 && index === 2) ? 'active' : ''} key={label}>
                <Icon size={15} />
                <small>{label}</small>
              </span>
            ))}
          </div>
        </div>
      </div>

      <div className="floating-note floating-note--top">
        <span><BellRing size={16} /></span>
        <div><strong>Chegando ao porto</strong><small>A 1,2 km de você</small></div>
      </div>
      <div className="floating-note floating-note--bottom">
        <span><CloudOff size={16} /></span>
        <div><strong>Modo offline ativo</strong><small>Seus dados estão seguros</small></div>
      </div>
    </div>
  )
}

function App() {
  const [phoneScreen, setPhoneScreen] = useState(0)
  const [profile, setProfile] = useState('passenger')
  const [openFaq, setOpenFaq] = useState(0)
  const [menuOpen, setMenuOpen] = useState(false)

  useEffect(() => {
    const interval = window.setInterval(() => {
      setPhoneScreen((current) => (current + 1) % 3)
    }, 4200)
    return () => window.clearInterval(interval)
  }, [])

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => entries.forEach((entry) => {
        if (entry.isIntersecting) entry.target.classList.add('is-visible')
      }),
      { threshold: 0.12 },
    )
    const elements = document.querySelectorAll('[data-reveal]')
    elements.forEach((element) => observer.observe(element))
    return () => observer.disconnect()
  }, [])

  const currentProfile = profileContent[profile]

  return (
    <main>
      <header className="navbar">
        <div className="container navbar__inner">
          <Brand />
          <nav className={`navbar__links ${menuOpen ? 'is-open' : ''}`} aria-label="Navegação principal">
            <a href="#recursos" onClick={() => setMenuOpen(false)}>Recursos</a>
            <a href="#como-funciona" onClick={() => setMenuOpen(false)}>Como funciona</a>
            <a href="#para-quem" onClick={() => setMenuOpen(false)}>Para quem é</a>
            <a href="#duvidas" onClick={() => setMenuOpen(false)}>Dúvidas</a>
            <DownloadButton compact />
          </nav>
          <button
            className="menu-button"
            aria-label={menuOpen ? 'Fechar menu' : 'Abrir menu'}
            aria-expanded={menuOpen}
            onClick={() => setMenuOpen((current) => !current)}
          >
            {menuOpen ? <X /> : <Menu />}
          </button>
        </div>
      </header>

      <section className="hero" id="inicio">
        <div className="hero__noise" />
        <div className="container hero__grid">
          <div className="hero__copy">
            <span className="eyebrow"><span className="eyebrow__dot" /> Mobilidade fluvial inteligente</span>
            <h1>O rio conecta.<br /><em>A gente mostra o caminho.</em></h1>
            <p>
              Acompanhe embarcações em tempo real, receba alertas de chegada e viaje pela Amazônia com mais informação e tranquilidade.
            </p>
            <div className="hero__actions">
              <DownloadButton light />
              <a className="text-link" href="#como-funciona">
                Conhecer o app <ArrowRight size={18} />
              </a>
            </div>
            <div className="hero__meta">
              <span><Check size={15} /> Download direto</span>
              <span><Check size={15} /> Feito para Android</span>
              <span><Check size={15} /> Versão 1.0.0</span>
            </div>
          </div>

          <div className="hero__demo">
            <PhoneDemo screen={phoneScreen} />
            <div className="demo-dots" aria-label="Telas demonstradas">
              {[0, 1, 2].map((screen) => (
                <button
                  key={screen}
                  className={phoneScreen === screen ? 'active' : ''}
                  onClick={() => setPhoneScreen(screen)}
                  aria-label={`Ver tela ${screen + 1}`}
                />
              ))}
            </div>
          </div>
        </div>
        <div className="hero__river" aria-hidden="true">
          <svg viewBox="0 0 1440 110" preserveAspectRatio="none">
            <path d="M0 74C190 20 338 92 526 56S869 16 1057 51s269 30 383 4v55H0Z" fill="#f5f3ec" />
          </svg>
        </div>
      </section>

      <section className="trust-strip">
        <div className="container trust-strip__inner">
          <div><span><Satellite size={21} /></span><p><strong>GPS em tempo real</strong><small>Posição e trajeto no mapa</small></p></div>
          <div><span><CloudOff size={21} /></span><p><strong>Offline-first</strong><small>Preparado para conexão instável</small></p></div>
          <div><span><UsersRound size={21} /></span><p><strong>Dois perfis</strong><small>Passageiros e barqueiros</small></p></div>
        </div>
      </section>

      <section className="section features" id="recursos">
        <div className="container">
          <div className="section-heading" data-reveal>
            <span className="eyebrow eyebrow--dark">Tudo em um só lugar</span>
            <h2>Informação que acompanha<br />o ritmo do rio.</h2>
            <p>Recursos pensados para uma rotina onde distância e conectividade não podem ser barreiras.</p>
          </div>
          <div className="features__grid">
            {features.map(({ icon: Icon, title, text, color }, index) => (
              <article className="feature-card" data-reveal style={{ '--delay': `${index * 70}ms` }} key={title}>
                <span className={`feature-card__icon feature-card__icon--${color}`}><Icon size={23} /></span>
                <h3>{title}</h3>
                <p>{text}</p>
                <span className="feature-card__number">0{index + 1}</span>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="section steps" id="como-funciona">
        <div className="container steps__grid">
          <div className="steps__visual" data-reveal>
            <div className="route-card">
              <div className="route-card__header">
                <span><Route size={20} /></span>
                <div><small>ROTA EM ANDAMENTO</small><strong>Manaus → Careiro</strong></div>
                <i>AO VIVO</i>
              </div>
              <div className="route-card__track">
                <span className="route-stop route-stop--start"><i /><b>Manaus</b><small>Saída · 08:30</small></span>
                <span className="route-progress"><i /></span>
                <span className="route-boat"><Ship size={19} /></span>
                <span className="route-stop route-stop--end"><i /><b>Careiro</b><small>Previsão · 10:10</small></span>
              </div>
              <div className="route-card__footer">
                <span><Compass size={16} /><small>Velocidade</small><b>18 km/h</b></span>
                <span><Clock3 size={16} /><small>Tempo restante</small><b>42 min</b></span>
                <span><MapPin size={16} /><small>Distância</small><b>12,4 km</b></span>
              </div>
            </div>
            <span className="steps__blob steps__blob--one" />
            <span className="steps__blob steps__blob--two" />
          </div>
          <div className="steps__copy" data-reveal>
            <span className="eyebrow eyebrow--dark">Simples de usar</span>
            <h2>Da instalação à primeira viagem em poucos passos.</h2>
            <ol>
              <li><span>1</span><div><strong>Baixe e crie sua conta</strong><p>Instale o APK e escolha se você é passageiro ou barqueiro.</p></div></li>
              <li><span>2</span><div><strong>Encontre sua rota</strong><p>Busque embarcações e veja as viagens disponíveis no calendário.</p></div></li>
              <li><span>3</span><div><strong>Acompanhe pelo mapa</strong><p>Siga o trajeto em tempo real e receba alertas importantes.</p></div></li>
            </ol>
          </div>
        </div>
      </section>

      <section className="section profiles" id="para-quem">
        <div className="container">
          <div className="profiles__tabs" data-reveal>
            <button className={profile === 'passenger' ? 'active' : ''} onClick={() => setProfile('passenger')}>
              <UsersRound size={18} /> Sou passageiro
            </button>
            <button className={profile === 'boatman' ? 'active' : ''} onClick={() => setProfile('boatman')}>
              <Anchor size={18} /> Sou barqueiro
            </button>
          </div>
          <div className="profiles__panel" data-profile={profile}>
            <div className="profiles__copy">
              <span className="eyebrow eyebrow--dark">{currentProfile.eyebrow}</span>
              <h2>{currentProfile.title}</h2>
              <p>{currentProfile.description}</p>
              <ul>
                {currentProfile.bullets.map((bullet) => <li key={bullet}><Check size={16} /> {bullet}</li>)}
              </ul>
              <a href={APK_PATH} download="amazon-track.apk">Começar agora <ArrowRight size={17} /></a>
            </div>
            <div className="profiles__scene" aria-hidden="true">
              <div className="scene-sun" />
              <div className="scene-cloud scene-cloud--one" />
              <div className="scene-cloud scene-cloud--two" />
              <div className="scene-hills scene-hills--back" />
              <div className="scene-hills scene-hills--front" />
              <div className="scene-water">
                <span className="scene-boat"><Ship size={44} /></span>
              </div>
              <div className="scene-card">
                {profile === 'passenger' ? <BellRing size={18} /> : <Radio size={18} />}
                <span>
                  <strong>{profile === 'passenger' ? 'Chegada prevista' : 'Sinal compartilhado'}</strong>
                  <small>{profile === 'passenger' ? 'Em aproximadamente 42 min' : 'Rastreamento em andamento'}</small>
                </span>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="section faq" id="duvidas">
        <div className="container faq__grid">
          <div className="faq__heading" data-reveal>
            <span className="eyebrow eyebrow--dark">Dúvidas frequentes</span>
            <h2>Antes de<br />embarcar.</h2>
            <p>Informações rápidas para instalar e começar a usar.</p>
          </div>
          <div className="faq__list" data-reveal>
            {faqItems.map((item, index) => (
              <article className={openFaq === index ? 'active' : ''} key={item.question}>
                <button onClick={() => setOpenFaq(openFaq === index ? -1 : index)}>
                  <span>{item.question}</span><ChevronDown size={20} />
                </button>
                <div className="faq__answer"><p>{item.answer}</p></div>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="download-section">
        <div className="container download-card" data-reveal>
          <div className="download-card__waves" aria-hidden="true" />
          <div className="download-card__copy">
            <span className="eyebrow"><span className="eyebrow__dot" /> Disponível para Android</span>
            <h2>Leve o rio<br />com você.</h2>
            <p>Baixe o Amazon Track e transforme a forma como você se conecta às viagens fluviais.</p>
            <DownloadButton light />
            <small><ShieldCheck size={14} /> APK versão 1.0.0 · Download direto</small>
          </div>
          <div className="download-card__icon">
            <span><Smartphone size={90} strokeWidth={1.2} /></span>
            <i><ArrowDownToLine size={28} /></i>
          </div>
        </div>
      </section>

      <footer>
        <div className="container footer__top">
          <div>
            <Brand light />
            <p>Tecnologia para aproximar pessoas, rotas e comunidades pelos rios da Amazônia.</p>
            <div className="project-credits">
              <p><strong>Autor:</strong> João Gabriel da Silva Maciel</p>
              <p><strong>Coautora:</strong> Alica de Souza Miranda</p>
              <p><strong>Projeto:</strong> PIBITI/UFAM</p>
              <p><strong>Laboratório:</strong> NUPEC/LAMAP</p>
              <p><strong>Orientador:</strong> Prof. Dr. Hidelbrando Ferreira Rodriguez</p>
            </div>
          </div>
          <div className="footer__links">
            <a href="#recursos">Recursos</a>
            <a href="#como-funciona">Como funciona</a>
            <a href="#para-quem">Para quem é</a>
            <a href="#duvidas">Dúvidas</a>
          </div>
        </div>
        <div className="container footer__bottom">
          <span>© 2026 Amazon Track. Todos os direitos reservados.</span>
          <span>Feito para as rotas da Amazônia <Waves size={17} /></span>
        </div>
      </footer>
    </main>
  )
}

export default App
