import { PokemonDataSource } from '../data/DataSource';
import { AbilityInfo, PokeInformation, PokeType } from '../Model/Pokemon';
import { EvolutionChain, EvolutionData, Species } from '../Model/Revolution';
import { extractLastNumber, heightConverter, weightConverter } from '../utils/unitFormatConverter';
import { HttpErrorComponent, LoadComponent } from './Index';

interface PokemonRouterParams {
  pokeName: string;
  pokeId: number;
  pokeImage: string;
}

@Entry
@Component
struct PokeDetail {
  @State pokeName: string = '';
  @State pokeId: number = 0;
  @State image: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State isEvolutionLoading: boolean = false;
  @State evolutionError: boolean = false;
  @State pokeInfo: PokeInformation = new PokeInformation();
  @State types: PokeType[] = [];
  @State abilities: AbilityInfo[] = [];
  @State pokeEvolution: EvolutionData = new EvolutionData();
  @State evolutionSpecies: Species[] = [];
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as PokemonRouterParams;
    if (!params || params.pokeId <= 0) {
      this.errorMessage = 'This Pokémon could not be opened. Return to the list and try again.';
      return;
    }
    this.pokeName = params.pokeName;
    this.pokeId = params.pokeId;
    this.image = params.pokeImage;
    this.loadPokemon();
  }

  private async loadPokemon(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    this.evolutionError = false;
    this.evolutionSpecies = [];
    if (this.pokeId <= 0) {
      this.errorMessage = 'This Pokémon could not be opened. Return to the list and try again.';
      this.isLoading = false;
      return;
    }
    try {
      const source = new PokemonDataSource();
      this.pokeInfo = await source.getPokemonInfo(this.pokeId);
      this.types = this.pokeInfo.types.map((item) => item.type as PokeType);
      this.abilities = this.pokeInfo.abilities;
    } catch (error) {
      console.error('Failed to load Pokémon:', error);
      const message = `${error}`;
      this.errorMessage = message.includes('HTTP 429') ?
        'PokéAPI is temporarily busy (HTTP 429). Please try again shortly.' :
        message.includes('HTTP 404') ?
          'This Pokémon was not found (HTTP 404). Return to the list and try again.' :
          'Could not load Pokémon details. Check your connection and try again.';
      return;
    } finally {
      this.isLoading = false;
    }
    this.loadEvolution();
  }

  private async loadEvolution(): Promise<void> {
    this.isEvolutionLoading = true;
    this.evolutionError = false;
    this.evolutionSpecies = [];
    try {
      const source = new PokemonDataSource();
      const url = await source.getEvolutionUrl(this.pokeInfo.species.url);
      this.pokeEvolution = await source.getEvolutionChain(url);
      if (this.pokeEvolution.chain) {
        this.evolutionSpecies = this.extractSpeciesNames(this.pokeEvolution.chain);
      }
    } catch (error) {
      console.warn('Failed to load evolution chain:', error);
      this.evolutionError = true;
    } finally {
      this.isEvolutionLoading = false;
    }
  }

  private extractSpeciesNames(chain: EvolutionChain, result: Species[] = []): Species[] {
    result.push({ name: chain.species.name, url: chain.species.url });
    chain.evolves_to.forEach((nextChain) => {
      this.extractSpeciesNames(nextChain, result);
    });
    return result;
  }

  @Builder
  Header() {
    Row() {
      Text('Pokémon')
        .fontSize(26)
        .fontWeight(800)
        .fontColor('#0F0026')
        .layoutWeight(1);
      Image($r('app.media.home_icon'))
        .width(28)
        .height(28)
        .focusable(true)
        .accessibilityText('Home')
        .onClick(() => {
          this.getUIContext().getRouter().clear();
          this.getUIContext().getRouter().pushUrl({ url: 'pages/Index' });
        });
    }
    .width('100%')
    .padding({ top: 12, bottom: 8 });
  }

  @Builder
  PokemonTypes() {
    Row({ space: 8 }) {
      ForEach(this.types, (item: PokeType) => {
        Text(item.name)
          .fontSize(14)
          .fontWeight(700)
          .fontColor('#6024B5')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor('#F8F3FF')
          .borderRadius(12)
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({
              url: 'pages/TypeDetail',
              params: { url: item.url, typeName: item.name }
            });
          });
      }, (item: PokeType) => item.url);
    }
  }

  @Builder
  FactRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor('#5E5470')
        .layoutWeight(1);
      Text(value)
        .fontSize(16)
        .fontWeight(700)
        .fontColor('#0F0026');
    }
    .width('100%');
  }

  @Builder
  EvolutionItem(item: Species) {
    Column({ space: 4 }) {
      Image(`https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${extractLastNumber(item.url)}.png`)
        .width(80)
        .height(80);
      Text(item.name)
        .fontSize(15)
        .fontWeight(700)
        .fontColor('#0F0026')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis });
      Text(`#${extractLastNumber(item.url)}`)
        .fontSize(13)
        .fontColor('#5E5470');
    }
    .width(116)
    .padding(10)
    .backgroundColor('#F8F3FF')
    .borderRadius(14);
  }

  build() {
    Column({ space: 12 }) {
      this.Header();
      if (this.isLoading) {
        LoadComponent();
      } else if (this.errorMessage.length > 0) {
        HttpErrorComponent({ text: this.errorMessage });
        Button('Retry')
          .backgroundColor('#6024B5')
          .onClick(() => this.loadPokemon());
      } else {
        Scroll() {
          Column({ space: 16 }) {
            Column({ space: 8 }) {
              Image(this.image)
                .width(150)
                .height(150);
              Text(this.pokeName)
                .fontSize(28)
                .fontWeight(800)
                .fontColor('#0F0026')
                .textAlign(TextAlign.Center);
              Text(`#${this.pokeId}`)
                .fontSize(15)
                .fontWeight(600)
                .fontColor('#6024B5');
            }
            .width('100%')
            .padding(18)
            .backgroundColor('#FFFFFF')
            .borderRadius(18);

            Column({ space: 14 }) {
              Text('Details')
                .fontSize(20)
                .fontWeight(700)
                .fontColor('#0F0026');
              this.FactRow('Height', `${heightConverter(this.pokeInfo.height)} m`);
              this.FactRow('Weight', `${weightConverter(this.pokeInfo.weight)} kg`);
              Text('Types')
                .fontSize(15)
                .fontColor('#5E5470');
              this.PokemonTypes();
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .padding(18)
            .backgroundColor('#FFFFFF')
            .borderRadius(18);

            Column({ space: 10 }) {
              Text('Abilities')
                .fontSize(20)
                .fontWeight(700)
                .fontColor('#0F0026');
              ForEach(this.abilities, (item: AbilityInfo) => {
                Row() {
                  Text(item.ability.name)
                    .fontSize(16)
                    .fontWeight(600)
                    .fontColor('#0F0026')
                    .layoutWeight(1);
                  if (item.is_hidden) {
                    Text('Hidden')
                      .fontSize(13)
                      .fontColor('#6024B5');
                  }
                }
                .width('100%')
                .padding(12)
                .backgroundColor('#F8F3FF')
                .borderRadius(12)
                .onClick(() => {
                  this.getUIContext().getRouter().pushUrl({
                    url: 'pages/AbilityDetail',
                    params: { url: item.ability.url, abilityName: item.ability.name }
                  });
                });
              }, (item: AbilityInfo) => item.ability.url);
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .padding(18)
            .backgroundColor('#FFFFFF')
            .borderRadius(18);

            Column({ space: 12 }) {
              Text('Evolution')
                .fontSize(20)
                .fontWeight(700)
                .fontColor('#0F0026');
              if (this.isEvolutionLoading) {
                LoadingProgress().color('#6024B5').width(32).height(32);
              } else if (this.evolutionError) {
                Text('Evolution data is unavailable.')
                  .fontSize(15)
                  .fontColor('#5E5470');
                Button('Retry evolution')
                  .backgroundColor('#6024B5')
                  .onClick(() => this.loadEvolution());
              } else if (this.evolutionSpecies.length === 0) {
                Text('No evolution data is available.')
                  .fontSize(15)
                  .fontColor('#5E5470');
              } else {
                List({ scroller: this.scroller }) {
                  ForEach(this.evolutionSpecies, (item: Species) => {
                    ListItem() {
                      this.EvolutionItem(item);
                    }
                    .onClick(() => {
                      const id = extractLastNumber(item.url);
                      this.getUIContext().getRouter().pushUrl({
                        url: 'pages/PokeDetail',
                        params: {
                          pokeName: item.name,
                          pokeId: id,
                          pokeImage: `https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${id}.png`
                        }
                      });
                    });
                  }, (item: Species) => item.url);
                }
                .listDirection(Axis.Horizontal)
                .height(150);
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .padding(18)
            .backgroundColor('#FFFFFF')
            .borderRadius(18);
          }
          .width('100%')
          .padding({ bottom: 24 });
        }
        .layoutWeight(1);
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor('#F8F3FF');
  }
}
