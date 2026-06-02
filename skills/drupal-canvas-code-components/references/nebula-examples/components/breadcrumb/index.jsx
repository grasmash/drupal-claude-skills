import { getPageData } from "drupal-canvas";

const Breadcrumb = () => {
  const { breadcrumbs } = getPageData();
  const links = Array.from(breadcrumbs);
  return (
    links && (
      <nav role="navigation" aria-labelledby="system-breadcrumb">
        <h2 id="system-breadcrumb" className="sr-only">
          Breadcrumb
        </h2>
        <ol className="flex items-center whitespace-nowrap">
          {links.map(({ key, text, url }, index) => (
            <li key={key} className="inline-flex items-center">
              {url ? (
                <>
                  <a
                    href={url}
                    className="flex items-center text-sm text-gray-500 hover:text-blue-600 focus:text-blue-600 focus:outline-none dark:text-neutral-500 dark:hover:text-blue-500 dark:focus:text-blue-500"
                  >
                    {text}
                  </a>
                </>
              ) : (
                <span className="inline-flex items-center truncate text-sm font-semibold text-gray-800 dark:text-neutral-200">
                  {text}
                </span>
              )}
              {index !== links.length - 1 && (
                <svg
                  className="mx-2 size-4 shrink-0 text-gray-400 dark:text-neutral-600"
                  xmlns="http://www.w3.org/2000/svg"
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <path d="m9 18 6-6-6-6"></path>
                </svg>
              )}
            </li>
          ))}
        </ol>
      </nav>
    )
  );
};

export default Breadcrumb;
