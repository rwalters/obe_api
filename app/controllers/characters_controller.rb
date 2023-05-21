class CharactersController < ApplicationController
  before_action :set_character, only: %i[ show edit update destroy ]

  def search
    query = RMApi::Client.parse <<-'GRAPHQL'
  query($name: Name) {
    characters(filter: {name: $name}) {
    results {
      name
      status
      species
      gender
      episode {
        episode
      }
    }
  }
    GRAPHQL

    search_name = params.require(:name)
    puts "\n\n\n=====\nNAME PARAM\n"
    p search_name
    puts "\n\n\n=====\n"

    result = RMApi::Client.query(query, variables: {name: search_name})
    puts "\n\n\n=====\nRESULTS\n"
    p result
    puts "\n\n\n=====\n"

    @characters = Character.where(name: search_name)
  end

  # GET /characters or /characters.json
  def index
    @characters = Character.all
  end

  # GET /characters/1 or /characters/1.json
  def show
  end

  # GET /characters/new
  def new
    @character = Character.new
  end

  # GET /characters/1/edit
  def edit
  end

  # POST /characters or /characters.json
  def create
    @character = Character.new(character_params)

    respond_to do |format|
      if @character.save
        format.html { redirect_to character_url(@character), notice: "Character was successfully created." }
        format.json { render :show, status: :created, location: @character }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @character.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /characters/1 or /characters/1.json
  def update
    respond_to do |format|
      if @character.update(character_params)
        format.html { redirect_to character_url(@character), notice: "Character was successfully updated." }
        format.json { render :show, status: :ok, location: @character }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @character.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /characters/1 or /characters/1.json
  def destroy
    @character.destroy

    respond_to do |format|
      format.html { redirect_to characters_url, notice: "Character was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_character
      @character = Character.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def character_params
      params.require(:character).permit(:name, :status, :species, :gender, :image, :appearances)
    end
end
