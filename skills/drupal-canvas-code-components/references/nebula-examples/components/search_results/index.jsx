import { useState } from "react";
import { JsonApiClient } from "drupal-canvas";
import { DrupalJsonApiParams } from "drupal-jsonapi-params";
import useSWR from "swr";

const searchParams = new URLSearchParams(window.location.search);
const q = searchParams.get("q") || "";

const client = new JsonApiClient();

function getOffsetFromLink(link) {
  if (!link || !link.href) return null;
  try {
    const url = new URL(link.href);
    const offset = url.searchParams.get("page[offset]");
    return offset ? parseInt(offset, 10) : null;
  } catch {
    return null;
  }
}

export default function List() {
  // Pagination can't be cleanly done currently due to how Canvas sets up
  // @drupal-api-client/json-api-client with Jsona as the serializer by default.
  // @see https://www.drupal.org/project/api_client/issues/3426518
  const links = {};
  const [pageOffset, setPageOffset] = useState(0);

  const { data, error, isLoading } = useSWR(
    [
      "index--cms_content",
      {
        queryString: new DrupalJsonApiParams()
          .addFields("node--article", ["title", "path"])
          .addFields("canvas_page--canvas_page", ["title", "path"])
          .addFilter("fulltext", q)
          .addPageLimit(10)
          .addPageOffset(pageOffset)
          .getQueryString(),
      },
    ],
    ([type, options]) => client.getCollection(type, options),
  );

  const handlePage = (link) => {
    const offset = getOffsetFromLink(link);
    if (offset !== null) {
      setPageOffset(offset);
    }
  };

  if (error) return "An error has occurred.";
  if (isLoading) return "Loading...";

  return (
    <div>
      <h2 className="text-2xl font-bold">Search results</h2>
      <ul className="mt-2 space-y-3">
        {data.map((item, index) => (
          <li
            key={index}
            className="mb-1 border-b border-[#E5E7EB] py-3 font-semibold"
          >
            <h3 className="text-[#2563EB]">
              <a href={item?.path?.alias}>{item?.title}</a>
            </h3>
          </li>
        ))}
      </ul>
      <div className="mt-4 flex gap-2">
        {links?.prev && (
          <button
            onClick={() => handlePage(links.prev)}
            className="flex items-center justify-between rounded rounded-xl border border-[#E5E7EB] bg-white px-2 py-1 text-sm text-[#6B7280]"
          >
            <svg
              className="mr-1"
              width="16"
              height="16"
              viewBox="0 0 16 16"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M10 12L6 8L10 4"
                stroke="#4B5563"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
            Previous
          </button>
        )}
        {links?.next && (
          <button
            onClick={() => handlePage(links.next)}
            className="flex items-center justify-between rounded rounded-xl border border-[#E5E7EB] bg-white px-2 py-1 text-sm text-[#6B7280]"
          >
            Next
            <svg
              className="ml-1"
              width="16"
              height="16"
              viewBox="0 0 16 16"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M6 12L10 8L6 4"
                stroke="#4B5563"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </button>
        )}
      </div>
    </div>
  );
}
