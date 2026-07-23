/* eslint-disable ember/no-classic-components, ember/require-tagless-components */
import Component from "@ember/component";
import { ajax } from "discourse/lib/ajax";
import Category from "discourse/models/category";
import { ALL_TAGS_ID } from "discourse/select-kit/components/tag-drop";
import { i18n } from "discourse-i18n";
import BoxTag from "./box-tag";
import TagSelector from "./tag-selector";

function parseSetting(setting) {
  return setting.split("|").map((option) => option.trim());
}

export default class TagGroupFilter extends Component {
  dropdownGroups = [];
  boxGroups = [];

  get allTag() {
    return { id: ALL_TAGS_ID, name: i18n("tagging.all_tags") };
  }

  async didInsertElement() {
    super.didInsertElement(...arguments);

    if (!this.category) {
      return;
    }

    if (!this.element || this.isDestroying || this.isDestroyed) {
      return;
    }

    const categoryId = this.category.id;
    let allowedTagGroups = this.category.allowed_tag_groups;

    if (!Array.isArray(allowedTagGroups)) {
      try {
        const result = await Category.reloadById(categoryId);
        const category = this.site.updateCategory(result.category);
        const reloaded = category?.allowed_tag_groups;
        allowedTagGroups = Array.isArray(reloaded) ? reloaded : [];
      } catch {
        allowedTagGroups = [];
      }
    }

    if (
      this.isDestroying ||
      this.isDestroyed ||
      this.category?.id !== categoryId
    ) {
      return;
    }

    if (allowedTagGroups.length) {
      // get box style tag groups from setting
      const boxStyleSetting = parseSetting(settings.filter_type_box);
      let boxGroups = [];
      let dropdownGroups = [];

      // get allowed tag groups + tags for the category
      const { results } = await ajax(`/tag_groups/filter/search`, {
        data: { names: allowedTagGroups },
      });

      if (
        this.isDestroying ||
        this.isDestroyed ||
        this.category?.id !== categoryId
      ) {
        return;
      }

      results.forEach((tagGroup) => {
        // Backward compatibility for https://github.com/discourse/discourse/pull/36678
        // which changes API response from tag_names (string[]) to tags (object[])
        const tagSource = tagGroup.tags || tagGroup.tag_names || [];
        const group = {
          name: tagGroup.name,
          tags: tagSource.map((t) =>
            typeof t === "string"
              ? { id: t, name: t, slug: t }
              : { id: t.id, name: t.name, slug: t.slug }
          ),
        };

        // separate results into box/dropdown styles
        if (boxStyleSetting.includes(group.name)) {
          boxGroups.push(group);
        } else {
          dropdownGroups.push(group);
        }
      });

      this.set("boxGroups", boxGroups);
      this.set("dropdownGroups", dropdownGroups);
    } else {
      this.set("boxGroups", null);
      this.set("dropdownGroups", null);
    }
  }

  <template>
    {{#if this.boxGroups}}
      <div class="custom-box-groups">
        {{#each this.boxGroups as |group|}}
          <div class="custom-box-group">
            <h4>{{group.name}}</h4>

            <ul>
              <BoxTag
                @tag={{this.allTag}}
                @activeTag={{this.tag}}
                @category={{this.category}}
              />

              {{#each group.tags as |tag|}}
                <BoxTag
                  @tag={{tag}}
                  @activeTag={{this.tag}}
                  @category={{this.category}}
                />
              {{/each}}
            </ul>
          </div>
        {{/each}}
      </div>
    {{/if}}

    {{#if this.dropdownGroups}}
      <div class="custom-dropdown-groups">
        {{#each this.dropdownGroups as |group|}}
          <div class="custom-dropdown-group">
            <h4>{{group.name}}</h4>

            <TagSelector
              @allowedTags={{group.tags}}
              @currentCategory={{this.category}}
              @tag={{this.tag}}
            />
          </div>
        {{/each}}
      </div>
    {{/if}}
  </template>
}
