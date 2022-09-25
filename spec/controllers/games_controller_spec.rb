require 'rails_helper'

require 'support/my_spec_helper'

RSpec.describe GamesController, type: :controller do
  # обычный пользователь
  let(:user) { FactoryGirl.create(:user) }
  # админ
  let(:admin) { FactoryGirl.create(:user, is_admin: true) }
  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryGirl.create(:game_with_questions, user: user) }

  context 'Anon' do
    # из экшена show анона посылаем
    it 'kick from #show' do
      # вызываем экшен
      get :show, id: game_w_questions.id
      # проверяем ответ
      expect(response.status).not_to eq(200) # статус не 200 ОК
      expect(response).to redirect_to(new_user_session_path) # devise должен отправить на логин
      expect(flash[:alert]).to be # во flash должен быть прописана ошибка
    end

    context 'kick from #create' do
      before { post :create }

      it "don't create new game" do
        expect change(Game, :count).by(0)
      end

      it 'responce status is not 200' do
        expect(response.status).not_to eq(200)
      end

      it 'redirect to sign in' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'takes alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'kick from #answer' do
      before { put :answer, id: game_w_questions.id }

      it 'responce status is not 200' do
        expect(response.status).not_to eq(200)
      end

      it 'redirect to sign in' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'takes alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'kick from #take_money' do
      before { put :take_money, id: game_w_questions.id }

      it 'responce status is not 200' do
        expect(response.status).not_to eq(200)
      end

      it 'redirect to sign in' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'takes alert' do
        expect(flash[:alert]).to be
      end
    end
  end

  context 'Usual user' do
    # Этот блок будет выполняться перед каждым тестом в группе
    # Логиним юзера с помощью девайзовского метода sign_in
    before(:each) { sign_in user }

    it 'creates game' do
      # Создадим пачку вопросов
      generate_questions(15)

      # Экшен create у нас отвечает на запрос POST
      post :create
      # Вытаскиваем из контроллера поле @game
      game = assigns(:game)

      # Проверяем состояние этой игры: она не закончена
      # Юзер должен быть именно тот, которого залогинили
      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)
      # Проверяем, есть ли редирект на страницу этой игры
      # И есть ли сообщение об этом
      expect(response).to redirect_to(game_path(game))
      expect(flash[:notice]).to be
    end

    it '#show game' do
      # Показываем по GET-запросу
      get :show, id: game_w_questions.id
      # Вытаскиваем из контроллера поле @game
      game = assigns(:game)
      # Игра не закончена
      expect(game.finished?).to be_falsey
      # Юзер именно тот, которого залогинили
      expect(game.user).to eq(user)

      # Проверяем статус ответа (200 ОК)
      expect(response.status).to eq(200)
      # Проверяем рендерится ли шаблон show (НЕ сам шаблон!)
      expect(response).to render_template('show')
    end

    it 'answers correct' do
      # Дёргаем экшен answer, передаем параметр params[:letter]
      put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key
      game = assigns(:game)

      # Игра не закончена
      expect(game.finished?).to be_falsey
      # Уровень больше 0
      expect(game.current_level).to be > 0

      # Редирект на страницу игры
      expect(response).to redirect_to(game_path(game))
      # Флеш пустой
      expect(flash.empty?).to be_truthy
    end

    it "kick from another's game #show" do
      anothers_game = FactoryGirl.create(:game_with_questions)

      get :show, id: anothers_game.id
      # проверяем ответ
      expect(response.status).not_to eq(200) # статус не 200 ОК
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be # во flash должен быть прописана ошибка
    end

    it 'take_money before end of the game' do
      game_w_questions.update_attributes(current_level: 5)

      put :take_money, id: game_w_questions.id

      game = assigns(:game)

      expect(game.finished?).to be_truthy
      expect(game.prize).to eq 1000

      expect(response).to redirect_to(user_path(user))

      user.reload
      expect(user.balance).to eq 1000

      expect(flash.empty?).to be_falsey
    end

    it "can't start second game" do
      expect(game_w_questions.finished?).to be_falsey

      expect { post :create }.to change(Game, :count).by(0)

      game = assigns(:game)
      expect(game).to be_nil

      expect(response).to redirect_to(game_path(game_w_questions))
      expect(flash[:alert]).to be
    end

    context 'answer is incorrect' do
      let(:game) { assigns(:game) }
      let(:incorrect_answer_key) { ['a', 'b', 'c', 'd'].
        reject { |letter| letter == game_w_questions.current_game_question.correct_answer_key }.sample }

      before { put :answer, id: game_w_questions.id, letter: incorrect_answer_key }

      it 'is not correct answer' do
        answer_is_correct = assigns(:answer_is_correct)
        expect(answer_is_correct).to be_falsey
      end

      it 'end the game' do
        expect(game.finished?).to be_truthy
      end

      it 'game status is fail' do
        expect(game.status).to be :fail
      end

      it 'redirect to user profile' do
        expect(response).to redirect_to(user_path(user))
      end

      it 'takes alert' do
        expect(flash[:alert]).to be
      end
    end
  end
end
