#coding: utf-8
class Presenca < ActiveRecord::Base
  attr_accessible :aluno_id, :data, :horario, :justificativa_de_falta, :presenca, :reposicao, :fora_de_horario, :pontualidade

  belongs_to :aluno
  has_one :justificativa_de_falta, :dependent => :destroy

  validates_presence_of :aluno
  validates_presence_of :data
  validates_presence_of :horario

  def label
    "presença de " << aluno.nome
  end
end
