#coding: utf-8
class AlunosController < ApplicationController
  active_scaffold :aluno do |conf|
    conf.columns[:endereco].label = "Endereço"
    conf.columns[:cpf].label = "CPF"
    conf.columns[:telefones].label = "Telefone"
    conf.columns[:codigo_de_acesso].label = "Código de Acesso"
    conf.columns = [:id, :foto, :nome, :cpf, :email, :sexo, :data_nascimento, :codigo_de_acesso, :foto, :endereco, :telefones]
    conf.show.columns << :presencas
    conf.columns[:data_nascimento].options[:format] = :default
    conf.columns[:sexo].form_ui = :select
    conf.columns[:sexo].options = {:options => Aluno::SEX.map(&:to_sym)}
    conf.columns[:endereco].allow_add_existing = false
    conf.actions.swap :search, :field_search
    conf.field_search.human_conditions = true
    conf.field_search.columns = [:nome, :cpf, :email, :sexo, :data_nascimento]
  end

  def adiantar_aula
    error = ""

    if params[:data].blank?
      error << "<strong>Campo Data</strong> não pode ficar vazio!\n"
    end
    if params[:horario].blank?
      error << "<strong>Horário da Aula</strong> não pode ficar vazio!\n"
    end
    if params[:data_de_realocacao_adiantamento].blank?
      error << "<strong>Data Referente ao Horário do Dia</strong> não pode ficar vazio!\n"
    end
    if not error.blank?
      render :text => error and return
    end

    aluno_id = params[:aluno_id].to_i

    # Criar a falta
    horario_de_aula = HorarioDeAula.do_aluno_pelo_dia_da_semana(aluno_id, Date.parse(params[:data_de_realocacao_adiantamento]).wday)

    if horario_de_aula.nil?
      error << "Aluno não possui horario cadastrado para as #{Date::DAYNAMES[params[:data_de_realocacao_adiantamento].wday]}"
    end

    p = Presenca.create(:aluno_id => aluno_id, :data => params[:data_de_realocacao_adiantamento], :presenca => false, :horario => horario_de_aula[0].horario)
    JustificativaDeFalta.create(:presenca_id => p.id, :descricao => "adiantado para o dia #{Date.parse(params[:data]).strftime("%d/%m/%Y")} às #{params[:horario]}")

    # Criar o adiantamento
    Presenca.create(:aluno_id => aluno_id, :data => params[:data], :realocacao => true, :data_de_realocacao => params[:data_de_realocacao_adiantamento], :horario => params[:horario])

    render :text => error
  end

  def gravar_reposicao
    error = ""

    if params[:data].blank?
      error << "<strong>Campo Data</strong> não pode ficar vazio!\n"
    end
    if params[:horario].blank?
      error << "<strong>Horário da Aula</strong> não pode ficar vazio!\n"
    end
    if params[:data_de_realocacao_reposicao].blank?
      error << "<strong>Data Referente ao Horário do Dia</strong> não pode ficar vazio!\n"
    end
    if not error.blank?
      render :text => error and return
    end

    Presenca.create(:aluno_id => params[:aluno_id].to_i, :data => params[:data], :data_de_realocacao => params[:data_de_realocacao_reposicao], :horario => params[:horario], :realocacao => true)

    render :text => error
  end

  def justificar_falta
    error = ""

    if params[:horario].blank?
      error << "<strong>Horário da Aula</strong> não pode ficar vazio!\n"
    end
    if params[:justificativa].blank?
      error << "<strong>Justificativa</strong> não pode ficar vazio!"
    end
    if not error.blank?
      render :text => error and return
    end

    presenca = Presenca.create(:aluno_id => params[:aluno_id].to_i, :data => params[:data], :horario => params[:horario], :presenca => false, :realocacao => false, :fora_de_horario => false, :tem_direito_a_reposicao => true)
    JustificativaDeFalta.create(:descricao => params[:justificativa], :presenca_id => presenca.id)

    render :text => error
  end

  def gerar_codigo_de_acesso
    codigo = ""

    if data = params[:nascimento] and not data.blank?
      codigo = data[0..1] << data[3..4] << data[8..9]
      while(codigo_existe?(codigo))
        codigo << codigo[codigo.length - 1]
      end
    end

    render :text => codigo
  end

  def codigo_existe?(codigo)
    if id = params[:id] and not id.blank?
      Aluno.where("id <> ?", id.to_i).find_by_codigo_de_acesso(codigo)
    else
     Aluno.find_by_codigo_de_acesso(codigo)
    end
  end
end
