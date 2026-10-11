<script lang="ts">
  import presetStore from '../../stores/presetStore';
  import type { HudPreset } from '../../presets/types';

  let appliedFeedback: string | null = null;

  function selectPreset(preset: HudPreset) {
    if ($presetStore.activePreset.id === preset.id) return;
    const ok = presetStore.setPreset(preset.id);
    if (ok) {
      appliedFeedback = preset.id;
      setTimeout(() => {
        appliedFeedback = null;
      }, 2000);
    }
  }
</script>

<div class="presets-panel-container">
  <div class="panel-header">
    <div class="header-titles">
      <h2 class="panel-title">Presets de HUD</h2>
      <p class="panel-subtitle">
        Alterne dinamicamente o tema visual completo da sua interface. Cada preset reconfigura os status, velocímetro, moldura e disposição gráfica.
      </p>
    </div>
  </div>

  <!-- Cards Grid -->
  <div class="presets-grid">
    {#each $presetStore.presets as preset (preset.id)}
      {@const isActive = $presetStore.activePreset.id === preset.id}
      <div class="preset-card {isActive ? 'is-active' : ''}">
        <!-- Top Badge -->
        <div class="card-top-bar">
          <span
            class="preset-tag {isActive ? 'tag-active' : ''}"
            style="color: {isActive ? '#00ff88' : preset.preview.accentColor}; border-color: {isActive ? 'rgba(0, 255, 136, 0.4)' : 'rgba(255, 255, 255, 0.12)'};"
          >
            {isActive ? '★ ATIVO' : preset.tag}
          </span>
          <span class="preset-author">por {preset.author}</span>
        </div>

        <!-- Card Header Info -->
        <div class="card-main-info">
          <div
            class="preset-icon-box"
            style="background: {preset.preview.badgeColor}22; border-color: {preset.preview.badgeColor}55;"
          >
            <span class="preset-emoji">{preset.preview.icon}</span>
          </div>
          <div class="preset-text-wrap">
            <h3 class="preset-name">{preset.name}</h3>
            <p class="preset-desc">{preset.description}</p>
          </div>
        </div>

        <!-- Features Tags -->
        <div class="features-wrapper">
          {#each preset.features as feat}
            <span class="feat-tag">• {feat}</span>
          {/each}
        </div>

        <!-- Card Footer Action -->
        <div class="card-footer">
          {#if isActive}
            <button type="button" class="btn-preset active-btn" disabled>
              ✓ Estilo Ativo no Momento
            </button>
          {:else}
            <button
              type="button"
              class="btn-preset apply-btn"
              on:click={() => selectPreset(preset)}
            >
              {appliedFeedback === preset.id ? '✓ Aplicado com Sucesso!' : 'Ativar Este Preset'}
            </button>
          {/if}
        </div>
      </div>
    {/each}
  </div>

  <!-- Helpful Hint Footer -->
  <div class="hint-box">
    <span class="hint-icon">💡</span>
    <span class="hint-text">
      <strong>Dica Rápida:</strong> Você também pode alternar entre os estilos diretamente pelo chat a qualquer momento digitando <code>/preset beta</code> ou <code>/preset minimal</code>.
    </span>
  </div>
</div>

<style>
  .presets-panel-container {
    padding: 1.2rem 0.5rem 1.8rem 0.5rem;
    display: flex;
    flex-direction: column;
    gap: 1.2rem;
    font-family: 'Montserrat', sans-serif;
    color: #ffffff;
  }

  .panel-header {
    border-bottom: 1px solid rgba(255, 255, 255, 0.08);
    padding-bottom: 0.8rem;
  }

  .panel-title {
    font-size: 1.4rem;
    font-weight: 800;
    margin: 0;
    color: #ffffff;
    letter-spacing: -0.02em;
  }

  .panel-subtitle {
    margin: 0.35rem 0 0 0;
    font-size: 0.8rem;
    color: rgba(255, 255, 255, 0.65);
    line-height: 1.4;
  }

  .presets-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 1.1rem;
  }

  @media (max-width: 900px) {
    .presets-grid {
      grid-template-columns: 1fr;
    }
  }

  .preset-card {
    background: rgba(23, 23, 23, 0.85);
    border: 1px solid rgba(255, 255, 255, 0.10);
    border-radius: 14px;
    padding: 1.1rem;
    display: flex;
    flex-direction: column;
    gap: 0.9rem;
    transition: all 0.25s ease;
    box-shadow: 0 4px 14px rgba(0, 0, 0, 0.35);
  }

  .preset-card:hover {
    border-color: rgba(245, 185, 69, 0.40);
    transform: translateY(-2px);
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.55);
  }

  .preset-card.is-active {
    border-color: rgba(245, 185, 69, 0.80);
    background: linear-gradient(145deg, rgba(30, 26, 18, 0.95) 0%, rgba(18, 20, 26, 0.95) 100%);
    box-shadow: 0 0 20px rgba(229, 169, 60, 0.18), 0 8px 24px rgba(0, 0, 0, 0.6);
  }

  .card-top-bar {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .preset-tag {
    font-size: 0.65rem;
    font-weight: 800;
    letter-spacing: 0.06em;
    padding: 0.2rem 0.55rem;
    border-radius: 6px;
    border: 1px solid;
    background: rgba(0, 0, 0, 0.35);
    text-transform: uppercase;
  }

  .preset-tag.tag-active {
    background: rgba(0, 255, 136, 0.12);
  }

  .preset-author {
    font-size: 0.7rem;
    color: rgba(255, 255, 255, 0.40);
    font-weight: 600;
  }

  .card-main-info {
    display: flex;
    align-items: flex-start;
    gap: 0.85rem;
  }

  .preset-icon-box {
    width: 42px;
    height: 42px;
    border-radius: 10px;
    border: 1px solid;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }

  .preset-emoji {
    font-size: 1.4rem;
  }

  .preset-text-wrap {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
  }

  .preset-name {
    margin: 0;
    font-size: 0.95rem;
    font-weight: 800;
    color: #ffffff;
    line-height: 1.2;
  }

  .preset-desc {
    margin: 0;
    font-size: 0.74rem;
    color: rgba(255, 255, 255, 0.68);
    line-height: 1.35;
  }

  .features-wrapper {
    display: flex;
    flex-wrap: wrap;
    gap: 0.35rem;
    background: rgba(0, 0, 0, 0.25);
    padding: 0.5rem 0.65rem;
    border-radius: 8px;
    border: 1px solid rgba(255, 255, 255, 0.05);
  }

  .feat-tag {
    font-size: 0.68rem;
    font-weight: 600;
    color: rgba(255, 255, 255, 0.75);
    white-space: nowrap;
  }

  .card-footer {
    margin-top: auto;
    padding-top: 0.4rem;
  }

  .btn-preset {
    width: 100%;
    font-family: inherit;
    font-size: 0.8rem;
    font-weight: 800;
    padding: 0.55rem 0.8rem;
    border-radius: 8px;
    cursor: pointer;
    transition: all 0.2s ease;
    border: none;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .apply-btn {
    background: linear-gradient(135deg, #e5a93c 0%, #b37e20 100%);
    color: #0b0e14;
    box-shadow: 0 4px 12px rgba(229, 169, 60, 0.25);
  }

  .apply-btn:hover {
    background: linear-gradient(135deg, #f5b945 0%, #e5a93c 100%);
    box-shadow: 0 6px 16px rgba(245, 185, 69, 0.40);
    transform: translateY(-1px);
  }

  .active-btn {
    background: rgba(0, 255, 136, 0.14);
    border: 1px solid rgba(0, 255, 136, 0.35);
    color: #00ff88;
    cursor: default;
  }

  .hint-box {
    background: rgba(229, 169, 60, 0.08);
    border: 1px solid rgba(229, 169, 60, 0.25);
    border-radius: 10px;
    padding: 0.65rem 0.9rem;
    display: flex;
    align-items: center;
    gap: 0.6rem;
    font-size: 0.75rem;
    color: rgba(255, 255, 255, 0.85);
  }

  .hint-icon {
    font-size: 1rem;
  }

  .hint-text code {
    background: rgba(0, 0, 0, 0.45);
    padding: 0.15rem 0.4rem;
    border-radius: 4px;
    color: #f5b945;
    font-weight: 700;
  }
</style>
