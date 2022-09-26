require 'rails_helper'

RSpec.describe 'games/help', type: :view do
  # Перед началом теста подготовим объекты
  let(:game) { FactoryGirl.build_stubbed(:game) }
  let(:help_hash) { {friend_call: 'Сережа считает, что это вариант D'} }

  # Проверяем, что выводятся кнопки подсказок
  context 'renders help variant' do
    before { render_partial({}, game) }

    it '50/50 rendered' do
      expect(rendered).to match '50/50'
    end

    it 'friend call rendered' do
      expect(rendered).to match 'fa-phone'
    end

    it 'audience help rendered' do
      expect(rendered).to match 'fa-users'
    end
  end

  # Проверяем, что выводится текст подсказки «Звонок другу»
  it 'renders help info text' do
    render_partial(help_hash, game)

    expect(rendered).to match 'Сережа считает, что это вариант D'
  end

  # Проверяем, что если была использована подсказка 50/50, то такая кнопка не выводится
  it 'does not render used help variant' do
    game.fifty_fifty_used = true

    render_partial(help_hash, game)

    expect(rendered).not_to match '50/50'
  end

  private

  # Метод, который рендерит фрагмент с нужными объектами
  def render_partial(help_hash, game)
    render partial: 'games/help', object: help_hash, locals: {game: game}
  end
end
