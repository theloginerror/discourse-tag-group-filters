import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import sinon from "sinon";
import Category from "discourse/models/category";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import TagGroupFilter from "../../discourse/components/tag-group-filter";

const CATEGORY = {
  id: 5,
  name: "General",
  slug: "general",
  path: "/c/general/5",
};

const TAG_GROUP_SEARCH = {
  results: [
    {
      name: "Product",
      tags: [{ id: 1, name: "widgets", slug: "widgets" }],
    },
  ],
};

module("Integration | Component | tag-group-filter", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    pretender.get("/tag_groups/filter/search", () =>
      response(TAG_GROUP_SEARCH)
    );
  });

  hooks.afterEach(function () {
    sinon.restore();
  });

  test("fetches the full category when allowed_tag_groups is missing", async function (assert) {
    // A category from the site payload has no `allowed_tag_groups`, so the
    // component must reload the full category before it can render filters.
    pretender.get("/c/5/show.json", () =>
      response({ category: { id: 5, allowed_tag_groups: ["Product"] } })
    );

    this.set("category", { ...CATEGORY });
    this.set("tag", null);

    await render(
      <template>
        <TagGroupFilter @category={{this.category}} @tag={{this.tag}} />
      </template>
    );

    assert
      .dom(".custom-dropdown-group h4")
      .hasText(
        "Product",
        "renders the filter after reloading the full category"
      );
  });

  test("does not error when the category reload fails", async function (assert) {
    pretender.get("/c/5/show.json", () => response(404, {}));

    this.set("category", { ...CATEGORY });
    this.set("tag", null);

    await render(
      <template>
        <TagGroupFilter @category={{this.category}} @tag={{this.tag}} />
      </template>
    );

    assert
      .dom(".custom-dropdown-group")
      .doesNotExist(
        "renders no filters when the full category cannot be loaded"
      );
  });

  test("does not reload when allowed_tag_groups is already present", async function (assert) {
    const reload = sinon.spy(Category, "reloadById");

    this.set("category", { ...CATEGORY, allowed_tag_groups: ["Product"] });
    this.set("tag", null);

    await render(
      <template>
        <TagGroupFilter @category={{this.category}} @tag={{this.tag}} />
      </template>
    );

    assert.true(reload.notCalled, "does not fetch the full category");
    assert
      .dom(".custom-dropdown-group h4")
      .hasText("Product", "renders the filter from the preloaded category");
  });
});
