import { PokemonDataSource } from '../data/DataSource';
import { EffectEntry, Pokemon } from '../Model/AbilityEffect';
import { extractLastNumber } from '../utils/unitFormatConverter';
import { HttpErrorComponent, LoadComponent } from './Index';

interface AbilityRouterParams {
  url: string;
  abilityName: string;
}

@Entry
@Component
struct AbilityDetail {
  @State url: string = '';
  @State abilityName: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State effectInfo: EffectEntry = new EffectEntry();
  @State abilityPokemonList: Pokemon[] = [];
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as AbilityRouterParams;
    if (!params || !params.url) {
      this.errorMessage = 'This ability could not be opened. Return to the Pokémon and try again.';
      return;
    }
    this.url = params.url;
    this.abilityName = params.abilityName;
    this.loadAbility();
  }

  private async loadAbility(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const source = new PokemonDataSource();
      const ability = await source.getAbilityDetail(this.url);
      const englishEffect = ability.effect_entries.find((item) => item.language?.name === 'en');
      this.effectInfo = englishEffect || new EffectEntry();
      this.abilityPokemonList = ability.pokemon.map((item) => item.pokemon);
    } catch (error) {
      console.error('Failed to load ability:', error);
      this.errorMessage = 'Could not load ability. Check your connection and try again.';
    } finally {
      this.isLoading = false;
    }
  }

  private openPokemon(item: Pokemon): void {
    const id = extractLastNumber(item.url);
    try {
      this.getUIContext().getRouter().pushUrl({
        url: 'pages/PokeDetail',
        params: {
          pokeName: item.name,
          pokeId: id,
          pokeImage: `https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${id}.png`
        }
      });
    } catch (error) {
      console.error('Could not open Pokémon details:', error);
    }
  }

  @Builder
  Header() {
    Row() {
      Text('Ability')
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
  PokemonRow(item: Pokemon) {
    Row({ space: 12 }) {
      Image(`https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${extractLastNumber(item.url)}.png`)
        .width(60)
        .height(60)
        .backgroundColor('#F8F3FF')
        .borderRadius(14);
      Text(item.name)
        .fontSize(17)
        .fontWeight(700)
        .fontColor('#0F0026')
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis });
      Text(`#${extractLastNumber(item.url)}`)
        .fontSize(13)
        .fontColor('#5E5470');
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ bottom: 10 });
  }

  build() {
    Column({ space: 12 }) {
      this.Header();
      if (this.isLoading) {
        LoadComponent({ label: 'Loading ability…' });
      } else if (this.errorMessage.length > 0) {
        HttpErrorComponent({ text: this.errorMessage });
        Button('Retry')
          .backgroundColor('#6024B5')
          .onClick(() => this.loadAbility());
      } else {
        Scroll() {
          Column({ space: 16 }) {
            Text(this.abilityName)
              .fontSize(30)
              .fontWeight(800)
              .fontColor('#0F0026')
              .width('100%')
              .padding(20)
              .backgroundColor('#FFFFFF')
              .borderRadius(18);

            Column({ space: 10 }) {
              Text('Effect')
                .fontWeight(700)
                .fontSize(20)
                .fontColor('#0F0026');
              Text(this.effectInfo.short_effect || 'No English effect description is available.')
                .fontSize(16)
                .fontColor('#0F0026')
                .lineHeight(24);
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .padding(18)
            .backgroundColor('#FFFFFF')
            .borderRadius(16);

            Text(`Pokémon with ${this.abilityName}`)
              .fontWeight(700)
              .fontSize(20)
              .fontColor('#0F0026');

            if (this.abilityPokemonList.length === 0) {
              Text('No Pokémon are listed for this ability.')
                .fontSize(16)
                .fontColor('#5E5470')
                .width('100%')
                .padding(18)
                .backgroundColor('#FFFFFF')
                .borderRadius(16);
            } else {
              List({ scroller: this.scroller }) {
                ForEach(this.abilityPokemonList, (item: Pokemon) => {
                  ListItem() {
                    this.PokemonRow(item);
                  }
                  .onClick(() => this.openPokemon(item));
                }, (item: Pokemon) => item.url);
              }
              .height(400);
            }
          }
          .width('100%')
          .padding({ bottom: 24 })
          .alignItems(HorizontalAlign.Start);
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
