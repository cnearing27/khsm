# (c) goodprogrammer.ru

require 'rails_helper'

# Тестовый сценарий для модели игрового вопроса, в идеале весь наш функционал
# (все методы) должны быть протестированы.
RSpec.describe GameQuestion, type: :model do
  # Задаем локальную переменную game_question, доступную во всех тестах этого
  # сценария: она будет создана на фабрике заново для каждого блока it,
  # где она вызывается.
  let(:game_question) do
    FactoryGirl.create(:game_question, a: 2, b: 1, c: 4, d: 3)
  end

  # Группа тестов на игровое состояние объекта вопроса
  context 'game status' do
    # Тест на правильную генерацию хэша с вариантами
    it 'correct .variants' do
      expect(game_question.variants).to eq(
        'a' => game_question.question.answer2,
        'b' => game_question.question.answer1,
        'c' => game_question.question.answer4,
        'd' => game_question.question.answer3
      )
    end

    it 'correct .answer_correct?' do
      # Именно под буквой b в тесте мы спрятали указатель на верный ответ
      expect(game_question.answer_correct?('b')).to be_truthy
    end

    it 'correct .level?' do
      expect(game_question.level).to eq(game_question.question.level)
    end

    it 'correct .text?' do
      expect(game_question.text).to eq(game_question.question.text)
      expect(game_question.answer_correct?('b')).to be_truthy
    end
  end

  describe '#correct_answer_key' do
    it 'return correct answer key' do
      expect(game_question.correct_answer_key).to eq('b')
    end
  end

  context 'user helpers' do
    it 'correct audience_help' do
      # Проверяем, что объект не включает эту подсказку
      expect(game_question.help_hash).not_to include(:audience_help)

      # Добавили подсказку. Этот метод реализуем в модели
      # GameQuestion
      game_question.add_audience_help

      # Ожидаем, что в хеше появилась подсказка
      expect(game_question.help_hash).to include(:audience_help)

      # Дёргаем хеш
      ah = game_question.help_hash[:audience_help]
      # Проверяем, что входят только ключи a, b, c, d
      expect(ah.keys).to contain_exactly('a', 'b', 'c', 'd')
    end
  end

  describe '#help_hash' do
    before do
      expect(game_question.help_hash).to eq({})
      game_question.help_hash[:some_key1] = 'blabla1'
      game_question.help_hash['some_key2'] = 'blabla2'
      expect(game_question.save).to be_truthy
    end

    let(:gq) { GameQuestion.find(game_question.id) }

    it 'right hash' do
      expect(gq.help_hash).to eq({some_key1: 'blabla1', 'some_key2' => 'blabla2'})
    end
  end

  describe '#add_fifty_fifty' do
    before do
      expect(game_question.help_hash).not_to include(:fifty_fifty)
      game_question.add_fifty_fifty
    end

    it 'help_hash include 50/50' do
      expect(game_question.help_hash).to include(:fifty_fifty)
    end

    let(:ff) { game_question.help_hash[:fifty_fifty] }

    it 'help_hash include right key' do
      expect(ff).to include('b')
    end

    it 'help_hash include only 2 keys' do
      expect(ff.size).to eq 2
    end
  end

  describe '#add_friend_call' do
    before do
      expect(game_question.help_hash).not_to include(:friend_call)
      game_question.add_friend_call
    end

    it 'help_hash include friend_call' do
      expect(game_question.help_hash).to include(:friend_call)
    end

    let(:fc) { game_question.help_hash[:friend_call] }

    it 'friend_call in help_hash include text' do
      expect(fc.index("считает, что это вариант")).to be
    end

    it 'friend_call in help_hash include letter' do
      expect(fc).to match(/[ABCD]/)
    end
  end
end
